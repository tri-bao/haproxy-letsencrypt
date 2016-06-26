#!/usr/bin/env bash

STAGING=""
if [ "$1" == "staging" ]; then
    STAGING="--staging"
fi

WEBROOT="/var/lib/haproxy"

if [ -n "$CERTS" ]; then
    certbot certonly -d "$CERTS" --text --webroot --webroot-path ${WEBROOT} \
        --renew-by-default --agree-tos --email ${EMAIL} $STAGING \
        || exit 1

    for site in `ls -1 /etc/letsencrypt/live`; do
        cat /etc/letsencrypt/live/$site/privkey.pem \
          /etc/letsencrypt/live/$site/fullchain.pem \
          | tee /etc/letsencrypt/live/$site/haproxy.pem >/dev/null
    done
fi

exit 0
