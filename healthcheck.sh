#!/bin/bash

/usr/bin/curl -s -k -L -I -m 3 http://127.0.0.1:${HTTP_PORT} >/dev/null

if [[ "$?" == "0" ]]; then
	webcheck_retval="0"
else
	webcheck_retval="1"
fi

/usr/bin/pgrep redis-server >/dev/null

if [[ "$?" == "0" ]]; then
        redis_retval="0"
else
        redis_retval="1"
fi

/usr/bin/pgrep rpcbind >/dev/null

if [[ "$?" == "0" ]]; then
        rpcbind_retval="0"
else
        rpcbind_retval="1"
fi

if [[ "$webcheck_retval" == "1" ]] || [[ "$redis_retval" == "1" ]] || [[ "$rpcbind_retval" == "1" ]]; then
	exit 1
fi
