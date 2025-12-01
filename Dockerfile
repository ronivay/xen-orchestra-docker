# Xen Orchestra builder container
FROM node:24-trixie AS xo-build

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
RUN yarn run turbo run build --filter @xen-orchestra/web

# Install plugins
RUN find /etc/xen-orchestra/packages/ -maxdepth 1 -mindepth 1 -not -name "xo-server" -not -name "xo-web" -not -name "xo-server-cloud" -not -name "xo-server-test" -not -name "xo-server-test-plugin" -exec ln -s {} /etc/xen-orchestra/packages/xo-server/node_modules \;

# libnbd / nbdkit builder container
FROM debian:trixie AS nbd-build

# Install set of dependencies for building libnbd and nbdkit
RUN apt update && \
    apt install -y git dh-autoreconf pkg-config make libxml2-dev ocaml libc-bin

ARG LIBNBD_REPO=https://gitlab.com/nbdkit/libnbd.git
ARG LIBNBD_VERSION=v1.23.4
ARG NBDKIT_REPO=https://gitlab.com/nbdkit/nbdkit.git
ARG NBDKIT_VERSION=v1.44.3

# Fetch libnbd and nbdkit sources at their required tags
RUN git clone --depth 1 --branch "${LIBNBD_VERSION}" "${LIBNBD_REPO}" /tmp/libnbd && \
    git clone --depth 1 --branch "${NBDKIT_VERSION}" "${NBDKIT_REPO}" /tmp/nbdkit

# Build libnbd
WORKDIR /tmp/libnbd
RUN autoreconf -i && \
    ./configure --prefix=/usr/local && \
    make -j"$(nproc)" && \
    make install DESTDIR=/opt/stage/libnbd

# Build nbdkit
WORKDIR /tmp/nbdkit
RUN autoreconf -i && \
    ./configure --prefix=/usr/local && \
    make -j"$(nproc)" && \
    make install DESTDIR=/opt/stage/nbdkit

# Runner container
FROM node:24-trixie-slim

LABEL org.opencontainers.image.authors="Roni Väyrynen <roni@vayrynen.info>"

# Install set of dependencies for running Xen Orchestra
RUN apt update && \
    apt install -y redis-server libvhdi-utils libxml2 python3-minimal python3-jinja2 lvm2 libfuse2t64 nfs-common netbase cifs-utils ca-certificates monit procps curl ntfs-3g

# Install forever for starting/stopping Xen-Orchestra
RUN npm install forever -g

# Copy built xen orchestra from xo-build container
COPY --from=xo-build /etc/xen-orchestra /etc/xen-orchestra

# Copy built libnbd, nbdkit from nbd-build container and update links using ldconfig
COPY --from=nbd-build /opt/stage/libnbd/usr/local /usr/local
COPY --from=nbd-build /opt/stage/nbdkit/usr/local /usr/local
RUN ldconfig

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
