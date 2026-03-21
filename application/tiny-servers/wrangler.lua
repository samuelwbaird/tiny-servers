local lfs = require('lfs')

local class = require('core.class')
local array = require('core.array')
local cache = require('core.cache')

local tiny_server = require('tiny-servers/tiny_server')

return class(function (wrangler)

	-- api definitions ----------------------------------------------------
	local synchronous_request_api = {
		handle_api = 'server_name:string, api_name:string, input:* -> response:*',
	}

	function wrangler:init()
		self.servers = cache()
		proxy_server(self, synchronous_request_api, 'inproc://tiny_server.wrangler.synchronous.request', zmq.REP, 'tiny_server.wrangler.synchronous.request')
	end
	
	
	local function handled(f, ...)
		local args = { ... }
		local wrapper = function ()
			return f(unpack(args))
		end
		return xpcall(wrapper, function (error)
			error = tostring(error)
			-- log the error with code position
			log(error)
			-- return the error without code position
			return error:match('%d: (.*)$') or error
		end)
	end
	
	function wrangler:handle_api(server_name, api_name, input)
		-- safely get or load the server
		local success, server = handled(self.get_server, self, server_name)
		if not success then
			return {
				success = false,
				error = server_name .. ' not available',
			}
		end
		
		local success, result = handled(server.handle_api, server, api_name, input)
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
		-- if we already have this server return it
		local server = self.servers:get(server_name)
		if server and server:check_if_fresh() then
			return server
		end
		
		-- if not then check if the path exists, if it does create and return a new server
		local path = '../servers/' .. server_name ..'/'
		if lfs.attributes(path) then
			server = tiny_server(server_name, path)
			self.servers:set(server_name, server)
			return server
		end
		
		-- otherwise
		log(server_name, '<server not found>')
		return nil
	end

end)