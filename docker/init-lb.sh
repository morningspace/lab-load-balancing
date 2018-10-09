#!/bin/sh
set -e

echo Howdy! Welcome to MorningSpace Lab: Load Balancing
echo

service rsyslog start

exec "$@"