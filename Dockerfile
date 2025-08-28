# builder container
FROM node:22-bookworm AS build

# Install set of dependencies to support building Xen Orchestra
RUN apt update && \
    apt install -y build-essential python3-minimal libpng-dev ca-certificates git fuse

# Fetch Xen-Orchestra sources from git stable branch
RUN git clone -b master https://github.com/vatesfr/xen-orchestra /etc/xen-orchestra

# Run build tasks against sources
# Docker buildx QEMU arm64 emulation is slow, so we set timeout for yarn
WORKDIR /etc/xen-orchestra
RUN yarn config set network-timeout 200000 && yarn && yarn build

# Builds the v6 webui
# Disabled for now: https://github.com/ronivay/xen-orchestra-docker/issues/54
#RUN yarn run turbo run build --filter @xen-orchestra/web

# Install plugins
RUN find /etc/xen-orchestra/packages/ -maxdepth 1 -mindepth 1 -not -name "xo-server" -not -name "xo-web" -not -name "xo-server-cloud" -not -name "xo-server-test" -not -name "xo-server-test-plugin" -exec ln -s {} /etc/xen-orchestra/packages/xo-server/node_modules \;

# Runner container
FROM node:22-bookworm-slim

LABEL org.opencontainers.image.authors="Roni Väyrynen <roni@vayrynen.info>"

# Install set of dependencies for running Xen Orchestra
RUN apt update && \
    apt install -y redis-server libvhdi-utils python3-minimal python3-jinja2 lvm2 nfs-common netbase cifs-utils ca-certificates monit procps curl ntfs-3g

# Install forever for starting/stopping Xen-Orchestra
RUN npm install forever -g

# Copy built xen orchestra from builder
COPY --from=build /etc/xen-orchestra /etc/xen-orchestra

# Logging
RUN ln -sf /proc/1/fd/1 /var/log/redis/redis-server.log && \
    ln -sf /proc/1/fd/1 /var/log/xo-server.log && \
    ln -sf /proc/1/fd/1 /var/log/monit.log

# Healthcheck
ADD healthcheck.sh /healthcheck.sh
RUN chmod +x /healthcheck.sh
HEALTHCHECK --start-period=1m --interval=30s --timeout=5s --retries=2 CMD /healthcheck.sh

# Copy xo-server configuration template
ADD conf/xo-server.toml.j2 /xo-server.toml.j2

# Copy monit configuration
ADD conf/monit-services /etc/monit/conf.d/services

# Copy startup script
ADD run.sh /run.sh
RUN chmod +x /run.sh

WORKDIR /etc/xen-orchestra/packages/xo-server

EXPOSE 80

CMD ["/run.sh"]
