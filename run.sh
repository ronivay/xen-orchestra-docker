#!/bin/bash

function StopProcesses {

	while [ $(/usr/bin/monit status | sed -n '/^Process/{n;p;}' | awk '{print $2}' | grep -c OK) != 0 ] ; do
		sleep 1
		/usr/bin/monit stop all
	done

	exit 0
}


if [[ ! -f /etc/xo-server/config.toml ]]; then
# generate configuration
set -a

[[ ! -d /etc/xo-server ]] && mkdir /etc/xo-server

HTTP_PORT=${HTTP_PORT:-"80"}
CERT_PATH=${CERT_PATH:-\'./temp-cert.pem\'}
KEY_PATH=${KEY_PATH:-\'./temp-key.pem\'}

/usr/bin/python3 -c 'import os
import sys
import jinja2
sys.stdout.write(
    jinja2.Template(sys.stdin.read()
).render(env=os.environ))' </xo-server.toml.j2 >/etc/xo-server/config.toml

set +a
# start services
fi

trap StopProcesses EXIT TERM

/usr/bin/monit && /usr/bin/monit start all

while true
do
	sleep 1d
done &

wait $!
