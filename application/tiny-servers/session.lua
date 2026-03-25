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
		self.database:ensure_table('sessions')
		self.database:ensure_column('sessions', 'session_id', 'TEXT')
		self.database:ensure_column('sessions', 'identity', 'TEXT')
		self.database:ensure_column('sessions', 'timestamp', 'INTEGER')
		self.database:ensure_index('sessions', { 'session_id' })
		self.database:ensure_index('sessions', { 'identity' })
		self.database:ensure_index('sessions', { 'timestamp' })

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
			self.database:query('DELETE FROM `sessions` WHERE `timestamp` < ?', { (now - (60 * 60 * 24 * 60)) })
			-- then read all sessions into memory
			for _, row in ipairs(self.database:select_all('sessions').rows) do
				self.sessions[row.session_id] = row
			end
		end
	end
	
	function session:get_session_data(session_id)
		self:reload_if_needed()
		local data = self.sessions[session_id]
		return {
			session_id = session_id,
			identity = data and data.identity or nil
		}
	end
	
	function session:handle_api(api_name, session, input)
		local success, result = pcall(self['api_' .. api_], self, session, input)
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
	
	-- /session/api/set_identity { session_id: '', identity: '' }
	function session:api_set_identity(session, input)
		local session_id = session.session_id
		-- validate
		
		local identity = input.identity
		-- normalise
		-- validate
		
		local now = utc_time()
		
		-- either insert or update the DB as required
		if self.sessions[session_id] then
			self.database:update('sessions', self.sessions[session_id].id, { identity = identity, timestamp = now })
			self.sessions[session_id].identity = identity
			self.sessions[session_id].timestamp = now
		else
			local id = self.database:insert('sessions', { session_id = session.session_id, identity = identity, timestamp = now })
			self.sessions[session_id] = {
				id = id,
				session_id = session_id,
				identity = identity,
				timestamp = now,
			}
		end
	end

end)