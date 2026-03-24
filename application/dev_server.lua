-- set package path for require libraries
package.path = 'submodules/brogue/source/?.lua;submodules/prelude/?.lua;' .. package.path

-- use rascal
local rascal = require('rascal.core')

-- configure logging
rascal.log_service:log_to_console(true)

-- launch a service to handle api calls to tiny servers
rascal.service('tiny-servers.session', {})
rascal.service('tiny-servers.wrangler', {})

-- configure an HTTP server
rascal.http_server('tcp://*:8080', 2, [[
	prefix('/', {
		prefix('js/', {
			static('submodules/hair/', nil, false),
			static('submodules/hair-mini/', nil, false),
		}),
		handler('tiny-servers.http_handler', {}),
	})
]])

-- last thing to do is run the main event loop
rascal.run_loop()