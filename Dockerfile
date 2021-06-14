FROM ubuntu:focal

MAINTAINER Roni Väyrynen <roni@vayrynen.info>

# Install set of dependencies to support running Xen-Orchestra

# build dependencies, git for fetching source and redis server for storing data
RUN apt update && \
    apt install -y build-essential redis-server libpng-dev git libvhdi-utils python2-minimal lvm2 nfs-common cifs-utils curl python3-jinja2

# Node v14
RUN curl -s -L https://deb.nodesource.com/setup_14.x | bash -

# yarn for installing node packages
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt update && \
    apt install -y yarn

# monit to keep an eye on processes
RUN apt -y install monit
ADD conf/monit-services /etc/monit/conf.d/services

# Fetch Xen-Orchestra sources from git stable branch
RUN git clone -b master https://github.com/vatesfr/xen-orchestra /etc/xen-orchestra

# Run build tasks against sources
RUN cd /etc/xen-orchestra && yarn && yarn build

# Install plugins
RUN find /etc/xen-orchestra/packages/ -maxdepth 1 -mindepth 1 -not -name "xo-server" -not -name "xo-web" -not -name "xo-server-cloud" -exec ln -s {} /etc/xen-orchestra/packages/xo-server/node_modules \;
RUN cd /etc/xen-orchestra && yarn && yarn build

# Install forever for starting/stopping Xen-Orchestra
RUN npm install forever -g

# cleanup
RUN yarn cache clean --all

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

# Copy startup script
ADD run.sh /run.sh
RUN chmod +x /run.sh

WORKDIR /etc/xen-orchestra/packages/xo-server

EXPOSE 80

CMD ["/run.sh"]
