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
docker pull ronivay/en-orchestra
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


