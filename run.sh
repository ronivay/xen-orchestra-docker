#!/bin/bash

function StopProcesses {

	while [ $(/usr/bin/monit status | sed -n '/^Process/{n;p;}' | awk '{print $2}' | grep -c OK) != 0 ] ; do
		sleep 1
		/usr/bin/monit stop all
	done

	exit 0
}


# start services

trap StopProcesses EXIT TERM

/usr/bin/monit && /usr/bin/monit start all

while true
do
	sleep 1d
done &

wait $!
