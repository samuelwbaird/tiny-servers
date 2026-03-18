-- set package path for require libraries
package.path = 'submodules/brogue/source/?.lua;' .. package.path

-- use rascal
local rascal = require('rascal.core')

-- configure logging
rascal.log_service:log_to_console(true)

-- launch a service to handle api calls to tiny servers
-- rascal.service('tiny-servers.tiny_server_wrangler', {})

-- configure an HTTP server
rascal.http_server('tcp://*:80', 2, [[
	prefix('/', {
		handler('tiny-servers.http_handler', {}),
	})
]])

-- last thing to do is run the main event loop
rascal.run_loop()