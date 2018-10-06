#!/bin/sh
set -e

sed -i.bak 's/^\(module.*imklog.*\)/# \1/g' /etc/rsyslog.conf
service rsyslog start

exec "$@"