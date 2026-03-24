local class = require('core.class')
local database = require('tiny-servers.database')

return class(function (session)

	-- api definitions ----------------------------------------------------
	local synchronous_request_api = {
		get_session_data = 'session_id:string -> response:*',
		handle_api = 'server_name:string, api_name:string, input:* -> response:*',
	}

	function session:init()
		self.database = database.for_filepath('db/session.sqlite')
		self.last_load = 0
		self:reload_if_needed()

		proxy_server(self, synchronous_request_api, 'inproc://tiny_server.session.synchronous.request', zmq.REP, 'tiny_server.session.synchronous.request')
	end
	
	function session:reload_if_needed()
		local now = utc_time()
		if now - self.last_load > 60 then
			self.last_load = now
			self.sessions = {}
			-- expire all sessions if we haven't done that recently
			-- then read all sessions into memory
		end
	end
	
	function session:get_session_data(session_id)
		self:reload_if_needed()
		
	end
	
	function session:handle_api(api_name, session, input)
		-- local success, result = handled(server.handle_api, server, api_name, input)
		-- if success then
		-- 	return {
		-- 		success = true,
		-- 		data = result,
		-- 	}
		-- else
		-- 	return {
		-- 		success = false,
		-- 		error = result,
		-- 	}
		-- end
	end

end)