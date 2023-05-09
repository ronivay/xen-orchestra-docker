# Xen-Orchestra docker container

[![image pulls](https://img.shields.io/docker/pulls/ronivay/xen-orchestra.svg)](https://hub.docker.com/r/ronivay/xen-orchestra) [![image size (tag)](https://img.shields.io/docker/image-size/ronivay/xen-orchestra/latest)](https://hub.docker.com/r/ronivay/xen-orchestra)

[![](https://github.com/ronivay/xen-orchestra-docker/actions/workflows/build.yml/badge.svg?branch=master)](https://github.com/ronivay/xen-orchestra-docker/actions?query=workflow%3Abuild)

This repository contains files to build Xen-Orchestra community edition docker container with all features and plugins installed

Latest tag is weekly build from xen orchestra sources master branch. Images are also tagged based on xo-server version.

Xen-Orchestra is a Web-UI for managing your existing XenServer infrastructure.

https://xen-orchestra.com/

Xen-Orchestra offers supported version of their product in an appliance (not running docker though), which i highly recommend if you are working with larger infrastructure.

#### Installation

- Clone this repository
```
git clone https://github.com/ronivay/xen-orchestra-docker
```

- build docker container manually

```
docker build -t xen-orchestra .
```

- or pull from dockerhub

```
docker pull ronivay/xen-orchestra
```

- run it with defaults values for testing purposes. 

```
docker run -itd -p 80:80 ronivay/xen-orchestra
```

Xen-Orchestra is now accessible at http://your-ip-address. Default credentials admin@admin.net/admin

- Other than testing, suggested method is to mount data paths from your host to preserve data

```
docker run -itd -p 80:80 -v /path/to/data/xo-server:/var/lib/xo-server -v /path/to/data/redis:/var/lib/redis ronivay/xen-orchestra
```

I also suggest adding --stop-timeout since there are multiple services inside single container and we want them to shutdown gracefully when container is stopped. 
Default timeout is 10 seconds which can be too short.

In recent versions docker containers run without privileges (root) or with reduced privileges. 
In those case XenOrchestra will not be able to mount nfs/smb shares for Remotes from within docker.
To fix that you will have to run docker with privileges: `--cap-add sys_admin --cap-add dac_read_search` option or `--priviledged` for all privileges. 
In case your system is also using an application security framework AppArmor or SELinux you will need to take additional steps.

For AppArmor you will have to add also `--security-opt apparmor:unconfined`. 

Below is an example command for running the app in a docker container with:

* automatic container start on boot / crash 
* enogh capabilities to mount nfs shares
* enough time to allow for proper service shutdown

```
docker run -itd \
  --stop-timeout 60 \
  --restart unless-stopped \
  --cap-add sys_admin \
  --cap-add dac_read_search \
  --security-opt apparmor:unconfined \
  -p 80:80 \
  -v /path/to/data/xo-server:/var/lib/xo-server \
  -v /path/to/data/redis:/var/lib/redis \
  ronivay/xen-orchestra

```

You may also use docker-compose. Copy configuration from below of example docker-compose.yml from github repository

```
version: '3'
services:
    xen-orchestra:
        restart: unless-stopped
        image: ronivay/xen-orchestra:latest
        container_name: xen-orchestra
        stop_grace_period: 1m
        ports:
            - "80:80"
            #- "443:443"
        environment:
            - HTTP_PORT=80
            #- HTTPS_PORT=443

            #redirect takes effect only if HTTPS_PORT is defined
            #- REDIRECT_TO_HTTPS=true

            #if HTTPS_PORT is defined and CERT/KEY paths are empty, a self-signed certificate will be generated
            #- CERT_PATH='/cert.pem'
            #- KEY_PATH='/cert.key'
        # capabilities are needed for NFS/SMB mount
        cap_add:
          - SYS_ADMIN
          - DAC_READ_SEARCH
        # additional setting required for apparmor enabled systems. also needed for NFS mount
        security_opt:
          - apparmor:unconfined
        volumes:
          - xo-data:/var/lib/xo-server
          - redis-data:/var/lib/redis
          # mount certificate files to container if HTTPS is set with cert/key paths
          #- /path/to/cert.pem:/cert.pem
          #- /path/to/cert.key:/cert.key
	  # mount your custom CA to container if host certificates are issued by it and you want XO to trust it
	  #- /path/to/ca.pem:/host-ca.pem
        # logging
        logging: &default_logging
            driver: "json-file"
            options:
                max-size: "1M"
                max-file: "2"
        # these are needed for file restore. allows one backup to be mounted at once which will be umounted after some minutes if not used (prevents other backups to be mounted during that)
        # add loop devices (loop1, loop2 etc) if multiple simultaneous mounts needed.
        #devices:
        #  - "/dev/fuse:/dev/fuse"
        #  - "/dev/loop-control:/dev/loop-control"
        #  - "/dev/loop0:/dev/loop0"

volumes:
  xo-data:
  redis-data:
```

#### Variables

`HTTP_PORT`

Listening HTTP port inside container

`HTTPS_PORT`

Listening HTTPS port inside container

`REDIRECT_TO_HTTPS`

Boolean value true/false. If set to true, will redirect any HTTP traffic to HTTPS. Requires that HTTPS_PORT is set. Defaults to: false

`CERT_PATH`

Path inside container for user specified PEM certificate file. Example: '/path/to/cert'
Note: single quotes are part of the value and mandatory!

If HTTPS_PORT is set and CERT_PATH not given, a self-signed certificate and key will be generated automatically.

`KEY_PATH`

Path inside container for user specified key file. Example: '/path/to/key'
Note: single quotes are part of the value and mandatory!

if HTTPS_PORT is set and KEY_PATH not given, a self-signed certificate and key will be generated automatically.
