-- the wrangler service: loads each tiny server when it's first used (or has
-- changed), and runs its api calls. It runs in a thread of its own, which
-- also owns every tiny server's databases

local lfs = require('lfs')

local tiny_server = require('tiny-servers.tiny_server')

local wrangler = class()

wrangler.api = {
	handle_api = 'server_name:string, api_name:string, session:*, input:* -> response:*',
}

function wrangler:init()
	self.servers = {}
end

-- call a function, logging any error with its code position, and returning
-- the error without it
local function handled(f, ...)
	return xpcall(f, function (error)
		error = tostring(error)
		log(error)
		return error:match('%d: (.*)$') or error
	end, ...)
end

function wrangler:handle_api(server_name, api_name, session, input)
	-- safely get or load the server
	local success, server = handled(self.get_server, self, server_name)
	if not success or not server then
		return {
			success = false,
			error = server_name .. ' not available',
		}
	end

	local success, result = handled(server.handle_api, server, api_name, session, input)
	if success then
		return {
			success = true,
			data = result,
		}
	else
		return {
			success = false,
			error = result,
		}
	end
end

function wrangler:get_server(server_name)
	-- if we already have this server, and its files have not changed, return it
	local server = self.servers[server_name]
	if server and server:check_if_fresh() then
		return server
	end

	-- if not then check if the path exists, if it does create and return a new server
	local path = '../servers/' .. server_name .. '/'
	if lfs.attributes(path) then
		server = tiny_server(server_name, path)
		self.servers[server_name] = server
		return server
	end

	log(server_name, '<server not found>')
	return nil
end

return wrangler
