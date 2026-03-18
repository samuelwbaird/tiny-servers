#! /bin/bash

# avoid issues with file/ports/descriptors limits
ulimit -n 10000

while [ 1 ]
do
	sleep 0.5
	echo ""
	echo `date` "- starting tiny servers dev server"

	# kill existing servers, bluntly all luajit instances
	killall -9 lua >/dev/null 2>/dev/null
	
	# ensure we're running from the correct folder
	cd /srv/application

	# launch the lua application, relaunch whenever relevant source files are changed
	cd /srv/application
	lua dev_server.lua &

	# monitor for any changes to the tiny-server code
	fswatch --monitor=poll_monitor -r1 -l 5 dev_server.lua brogue/ tiny-servers/
done