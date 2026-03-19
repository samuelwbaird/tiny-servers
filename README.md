# tiny-servers

To run locally install docker, and use docker compose:

	docker compose build
	docker compose up
	
The tiny-servers service will be up and running on http://localhost:8080/ or similar.

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
 * db will contain any sqlite DB files created for this server
 * html folder can contain any static files you want to serve for the frontend of your application, and will serve index.html by default
 * You can safely add any other files outside of these.


## development focus

* This configuration of tiny servers is designed for local development, so caching and DB optimisations are turned off, favouring easy edit and debug cycles over performance.
* The tiny server application will automatically restart if any source files change.
* Individual tiny servers will reload all lua files, if any lua files are detected as changed