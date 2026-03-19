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
		loop:add_interval(5000, self:delegate(self.slow_tick))
	end
	
	function wrangler:handle_api(server_name, api_name, input)
		log('handle_api', server_name)
		local server = self:get_server(server_name)
		if server then
			return server:handle_api(api_name, input)
		end
		return {
			success = true,
			error = nil,
			message = '',
			data = '',
		}
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
		log('tiny server not found', server_name)
		return nil
	end
	
	function wrangler:slow_tick()
		-- call clean up tick on all servers
	end

end)