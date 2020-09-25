# Xen-Orchestra docker container

This repository contains files to build Xen-Orchestra community edition docker container with all features and plugins installed

Latest tag is daily build from xen-orchestra master branch. Tagged releases follow xen-orchestra versioning.

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
In those case XenOrchestra will not be able to mount nfs shares for Remotes from within docker.
To fix that you will have to run docker with privileges: `--cap-add sys_admin` option or `--priviledged` for all privileges. 
In case your system is also using an application security framework AppArmor or SELinux you will need to take additional steps.

For AppArmor you will have to add also `--security-opt apparmor:unconfined`. 

Bellow is an example command for running the app in a docker container with:

* automatic container start on boot / crash 
* enogh capabilities to mount nfs shares
* enough time to allow for proper service shutdown

```
docker run -itd \
  --stop-timeout 60 \
  --restart unless-stopped \
  --cap-add sys_admin \
  --security-opt apparmor:unconfined \
  -p 80:80 \
  -v /path/to/data/xo-server:/var/lib/xo-server \
  -v /path/to/data/redis:/var/lib/redis \
  ronivay/xen-orchestra

```

