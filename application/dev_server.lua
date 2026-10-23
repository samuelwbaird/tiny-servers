-- tiny servers, a local development server
--
--   cd application && rascal dev_server.lua [port]     (default 8080)
--
--   session thread    serves tiny-servers.session (REP), owns db/session.sqlite
--   wrangler thread   serves tiny-servers.wrangler (REP), loads each tiny server
--                     under ../servers, runs its api calls, and owns its databases
--   main thread       serves http, see tiny-servers/http_handler.lua

local http = require('rascal.http')
local threads = require('rascal.threads')

local port = tonumber(arg[1]) or 8080

-- the services, each in a thread of its own
threads.start(function ()
	local services = require('rascal.services')
	local session = require('tiny-servers.session')
	services.serve('tiny-servers.session', 'REP', session.api, session())
end)

threads.start(function ()
	local services = require('rascal.services')
	local wrangler = require('tiny-servers.wrangler')
	services.serve('tiny-servers.wrangler', 'REP', wrangler.api, wrangler())
end)

-- the http server, with the shared front end libraries under /js/
local server = http.server()
server:prefix('/js/', {
	http.static('submodules/hair/'),
	http.static('submodules/hair-mini/'),
})
server:handle(require('tiny-servers.http_handler')())

log('tiny servers on http://127.0.0.1:' .. port .. '/')
server:listen('tcp://*:' .. port)
