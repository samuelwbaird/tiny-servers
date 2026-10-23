# tiny-servers

A local development server for tiny servers: small web apps, each a folder of static files plus Lua API functions, with sign in and SQLite databases provided. It runs on [rascal](https://github.com/samuelwbaird/rascal), a single executable Lua with SQLite, ZeroMQ, threads and HTTP built in.

## running locally

### with docker compose

Install docker, then:

	docker compose build
	docker compose up

The tiny-servers service will be up and running on http://localhost:8080/

The image downloads the rascal release given by `RASCAL_VERSION` in `application/Dockerfile`. The application and servers folders are mapped in as volumes, so edits are picked up without rebuilding.

### with rascal directly

Install rascal, eg. with Homebrew:

	brew install samuelwbaird/tap/rascal

or see [installing rascal](https://github.com/samuelwbaird/rascal#installing) for other options, including building it from source with `make install`. Then:

	git submodule update --init
	application/launch.sh

The server runs on http://localhost:8080/, or give a port, eg. `application/launch.sh 8081`. With [fswatch](https://github.com/emcrisostomo/fswatch) installed (eg. `brew install fswatch`), `launch.sh` restarts the server whenever the application code changes. Without it, it simply runs the server, which is the same as:

	cd application
	rascal dev_server.lua

To run with a local development build of rascal, put its `build/<platform>/bin` folder on the path, eg.

	PATH=~/github/rascal/build/darwin-arm64/bin:$PATH application/launch.sh

## tiny servers

Each tiny server is defined in its top level folder under servers, eg.

	http://localhost:8080/example/

To make a new server, duplicate the example folder under servers with a new name.

	server_name/
		api/
		db/
		html/
		server.lua

 * api folder should contain lua files, these will be loaded and executed on start up or reload.
   * functions using the naming convention `function api_something(args...)` will automatically be available as API calls via the tiny-servers JS module, eg. `await ts.api('something', [args...])`
   * do not rely on order of execution, use global variables to late bind references between different files
   * server.lua is the only exception, and if it exists it will be executed first, upon launch or reload the prepare function will also be executed (if it exists)
 * db will contain any sqlite DB files created for this server, with `database('name')`
 * html folder should contain any static files you want to serve for the frontend of your application, and will serve index.html by default

Lua files run in a sandbox with a limited set of globals, plus:
 * [prelude](https://github.com/samuelwbaird/rascal/blob/main/docs/modules/prelude.md), made global and strict, eg. `list()` and `class()`
 * `log(...)` and `utc_time()`
 * `database(name)`, a [rascal.database](https://github.com/samuelwbaird/rascal/blob/main/docs/modules/rascal.database.md) for this server, in its db folder

## development focus

This configuration of tiny servers is designed *for local development only*:

* sign in identies are not challenged, any email sign is automatically accepted, to allow easy testing as different hypothetical users
* caching is turned off, and every database query is logged, favouring easy edit and debug cycles over performance
* the tiny server application will automatically restart if any of its source files change (when run with fswatch)
* individual tiny servers will reload all lua files, if any lua files are detected as changed

## layout

	application/
		dev_server.lua          starts the session and wrangler threads, and the http server
		launch.sh               runs dev_server.lua, restarting it on changes
		tiny-servers/
			http_handler.lua    routes requests to api calls, or static files
			session.lua         the session service, sign in identities (db/session.sqlite)
			wrangler.lua        the wrangler service, loads tiny servers and runs their api calls
			tiny_server.lua     one tiny server, reloaded when its files change
			tiny_sandbox.lua    the environment a tiny server's lua files run in
		html/                   shared files, eg. /tiny-servers/api.js
		submodules/             hair and hair-mini, served under /js/
	servers/                    the tiny servers
