FROM ubuntu:24.04

# fswatch, to restart the server when the application code changes
RUN \
	apt-get update && \
	apt-get install -y --no-install-recommends ca-certificates curl fswatch && \
	rm -rf /var/lib/apt/lists/*

# rascal, a single static executable, for this image's architecture and
# checked against the release's checksums
ARG RASCAL_VERSION=0.1.0
ARG TARGETARCH
RUN \
	case "$TARGETARCH" in amd64) arch=x86_64 ;; arm64) arch=aarch64 ;; *) exit 1 ;; esac && \
	file=rascal-$RASCAL_VERSION-linux-$arch-static.tar.gz && \
	release=https://github.com/samuelwbaird/rascal/releases/download/v$RASCAL_VERSION && \
	cd /tmp && \
	curl -fsSLO "$release/$file" -O "$release/SHA256SUMS" && \
	grep " $file\$" SHA256SUMS | sha256sum -c - && \
	tar -xzf "$file" && \
	mv rascal-$RASCAL_VERSION-linux-$arch-static/rascal /usr/local/bin/rascal && \
	rm -rf /tmp/*

# the application is mapped in as a volume (see docker-compose.yml), so the
# launch script runs from there
CMD ["/srv/application/launch.sh"]
