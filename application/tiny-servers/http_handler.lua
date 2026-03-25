-- direct requests to either the shared tiny servers file, or individual tiny servers
-- handle static file requestss (with no caching for development), or api calls

local class = require('core.class')
local rascal = require('rascal.core')
local random_key = require('rascal.util.random_key')
local static_handler = require('rascal.http.static_handler')

return class(function (http_handler)

	function http_handler:init()
		self.session_request = rascal.registry:connect('tiny_server.session.synchronous.request')
		self.wrangler_request = rascal.registry:connect('tiny_server.wrangler.synchronous.request')
	end
	
	function http_handler:handle(request, context, response)		
		local path = request.url_path
		
		-- find the first fragment of the path, and see if its referencing a server
		local server = request.url_path:match('([^/%.]+)/')
		if server then
			-- capture the remaining path
			path = path:sub(#server + 2)
		end
		
		-- see if the request is an API request for a server
		if path:sub(1, 4) == 'api/' then
			-- all requests are assigned a session cookie if not present
			local cookie_header = request.headers.cookie or ''
			local session_id = cookie_header:match('session=([^;]*);?')
			-- if there wasn't a session cookie then set one
			local session = {
				session_id = session_id,
				identity = nil,
			}
			if session_id then
				session = self.session_request:get_session_data(session_id)
			else
				session_id = random_key.printable(64)
				response:set_header('Set-Cookie', 'session=' .. session_id .. '; Path=/; HttpOnly; SameSite=Strict; Max-Age=2592000;')
			end
			
			-- allow cross origin logging from other sites
			response:set_header('Access-Control-Allow-Origin', '*')
			response:set_header('Access-Control-Allow-Headers', 'CONTENT-TYPE')
			response:set_header('Access-Control-Allow-Methods', 'GET, POST', 'OPTIONS')
			if request.method:lower() == 'options' then
				response:set_status(200)
				return true
			end
			
			-- get these from the rest of the request
			local api_name = request:path_slugs()[3]
			local result = nil
			
			if api_name then
				local input = request:input() or request.url_vars
				if server == 'session' then
					result = self.session_request:handle_api(api_name, session, input)
				else
					result = self.wrangler_request:handle_api(server, api_name, session, input)
				end
			end
			
			if not result then
				result = {
					success = false,
					errror = 'unknown_api',
				}
			end
			
			response:set_json(result)
			return true
		end
		
		-- otherwise see if it can be served as static content from the specific server
		if server and server ~= 'session' and server ~= 'tiny-servers' then
			if self:static_content('../servers/' .. server .. '/html/', path, request, context, response) then
				return true
			end
		end
		
		-- or the shared application code
		return self:static_content('html/', path, request, context, response)
	end
		
	function http_handler:static_content(source_path, path, request, context, response)
		-- set a default path for static content if not given
		if not path or path == '' then
			path = 'index.html'
		elseif path:sub(-1, -1) == '/' then
			path = path .. 'index.html'
		end
		
		-- rewrite the path to the currently processed path
		request:rewrite_url_path(path)

		-- serve files without any cache as this is for local dev work
		response:set_header('cache-control', 'no-store')
		
		-- attempt to retrieve the file from the static path
		local static = static_handler(source_path, nil, false)
		return static:handle(request, context, response)
	end
	
end)