#!/bin/sh
# run the tiny servers development server with rascal, restarting it whenever
# the application's own code changes (tiny servers under ../servers reload
# themselves). Without fswatch it simply runs the server.
#
#   application/launch.sh [port]

cd "$(dirname "$0")" || exit 1

# avoid issues with file/ports/descriptors limits
ulimit -n 10000 2>/dev/null

if ! command -v fswatch >/dev/null 2>&1; then
	exec rascal dev_server.lua "$@"
fi

# files in docker volume mounts don't raise change events, so poll for them
monitor=
if [ "$(uname -s)" = Linux ]; then
	monitor=--monitor=poll_monitor
fi

pid=
trap 'kill $pid 2>/dev/null; exit' INT TERM

while true
do
	echo ""
	echo "$(date) - starting tiny servers dev server"
	rascal dev_server.lua "$@" &
	pid=$!

	# wait for any change to the tiny servers application code, then restart
	fswatch $monitor -r -1 -l 1 dev_server.lua tiny-servers/ >/dev/null
	kill $pid 2>/dev/null
	wait $pid 2>/dev/null
	sleep 0.5
done
