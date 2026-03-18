FROM ubuntu:24.04

# ubuntu level dependencies
RUN \
	apt-get update && \
	apt-get install -y libzmq3-dev sqlite3 libsqlite3-dev git lua5.1 luarocks fswatch psmisc
	
# lua rocks dependencies
RUN \
	luarocks install luafilesystem && \
	luarocks install lua-cjson && \
	luarocks install lua-cmsgpack && \
	luarocks install lsqlite3 && \
	luarocks install lua-llthreads2 && \
	luarocks install lzmq

# setup a launch script to wait for volume mount and then launch the lua application
COPY launch.sh /bin/launch.sh
RUN chmod a+x /bin/launch.sh
CMD "/bin/launch.sh"
