#!/bin/sh
set -e

echo "<h1>Greeting from $HOSTNAME</h1>" > /usr/share/nginx/html/healthz.html
nginx -g 'daemon off;'

exec "$@"