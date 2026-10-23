-- direct requests to either the shared tiny servers files, or individual tiny servers
-- handle static file requests (with no caching for development), or api calls
--
--   /<server>/api/<name>    an api call on a tiny server, run by the wrangler
--   /session/api/<name>     an api call on the session service
--   /<server>/<path>        a static file from ../servers/<server>/html/
--   /<path>                 a static file from html/, the shared tiny servers files
--
-- Each request is handled in a coroutine, and calls the session and wrangler
-- services with DEALER connections, so a slow api call only holds up its own request

local http = require('rascal.http')
local services = require('rascal.services')

-- better default json encoding for this use case
local cjson = require('cjson')
cjson.encode_empty_table_as_object(false)

-- a random session id, from letters and digits
local session_id_chars = '1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
local function random_session_id(length)
	local random = assert(io.open('/dev/urandom', 'rb'))
	local bytes = random:read(length)
	random:close()
	return (bytes:gsub('.', function (byte)
		local index = byte:byte() % #session_id_chars + 1
		return session_id_chars:sub(index, index)
	end))
end

local http_handler = class()

function http_handler:init()
	self.session = services.connect('tiny-servers.session', 'DEALER')
	self.wrangler = services.connect('tiny-servers.wrangler', 'DEALER')
	self.shared_static = http.static('html/')
end

function http_handler:handle(request, context)
	-- the path without its leading /
	local url_path = request.path:sub(2)
	local path = url_path

	-- find the first fragment of the path, and see if its referencing a server
	local server = url_path:match('([^/%.]+)/')
	if server then
		-- capture the remaining path
		path = path:sub(#server + 2)
	end

	-- see if the request is an API request for a server
	if path:sub(1, 4) == 'api/' then
		return self:api(request, server, url_path)
	end

	-- otherwise see if it can be served as static content from the specific server
	if server and server ~= 'session' and server ~= 'tiny-servers' then
		local response = self:static_content(http.static('../servers/' .. server .. '/html/'), path, request, context)
		if response then
			return response
		end
	end

	-- or the shared application code
	return self:static_content(self.shared_static, path, request, context)
end

function http_handler:api(request, server, url_path)
	local response = http.response()

	-- all requests are assigned a session cookie if not present
	local session_id = request.cookies.session
	local session = {
		session_id = session_id,
		identity = nil,
	}
	-- look up the session data, if the ID is a valid session id
	if session_id and #session_id == 64 and not session_id:match('[^%w]') then
		session = self.session:get_session_data(session_id)
	else
		session.session_id = random_session_id(64)
		response:set_header('set-cookie', 'session=' .. session.session_id .. '; Path=/; HttpOnly; SameSite=Strict; Max-Age=2592000;')
	end

	-- allow cross origin logging from other sites
	response:set_header('access-control-allow-origin', '*')
	response:set_header('access-control-allow-headers', 'CONTENT-TYPE')
	response:set_header('access-control-allow-methods', 'GET, POST, OPTIONS')
	if request.method == 'OPTIONS' then
		return response
	end

	-- the api name is the third part of the path, eg. example/api/<name>
	local slugs = {}
	for slug in url_path:gmatch('[^/]+') do
		slugs[#slugs + 1] = http.url_decode(slug)
	end
	local api_name = slugs[3]
	local result = nil

	if api_name then
		local input = request:input() or request.vars
		if server == 'session' then
			result = self.session:handle_api(api_name, session, input)
		else
			result = self.wrangler:handle_api(server, api_name, session, input)
		end
	end

	if not result then
		result = {
			success = false,
			error = 'unknown_api',
		}
	end

	return response:set_json(result)
end

function http_handler:static_content(static, path, request, context)
	-- serve the file at this path, with index.html by default
	local full_path = request.path
	request.path = path
	local response = static(request, context)
	request.path = full_path

	-- serve files without any cache as this is for local dev work
	if response then
		response:set_header('cache-control', 'no-store')
	end
	return response
end

return http_handler
