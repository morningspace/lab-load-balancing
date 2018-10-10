#!/bin/sh
set -e

cat WELCOME
service rsyslog start

exec "$@"