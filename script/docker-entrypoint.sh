#!/bin/sh
set -e
#set -x

# run rsyslog in background
rsyslogd

# genrate certificate if needed
#/certs.sh

# take all files that have .cfg suffix in /etc/haproxy.d folder
CONFIG_FILES=""
for FILE in `find /etc/haproxy.d -name "*.cfg" | sort`;
do
    CONFIG_FILES="$CONFIG_FILES -f $FILE";
done;

# first arg is `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- haproxy "$@"
fi

if [ "$1" = 'haproxy' ]; then
	# if the user wants "haproxy", let's use "haproxy-systemd-wrapper" instead so we can have proper reloadability implemented by upstream
	shift # "haproxy"
	set -- "$(which haproxy-systemd-wrapper)" $CONFIG_FILES -p /run/haproxy.pid "$@"
fi

exec "$@"
