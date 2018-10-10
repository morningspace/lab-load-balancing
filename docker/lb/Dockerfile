FROM ubuntu:bionic

LABEL maintainer="morningspace@yahoo.com"

COPY ./conf ./docker/lb/entrypoint.sh ./docker/lb/WELCOME /tmp/

RUN \
# install packages
    apt-get update && \
    apt-get install --no-install-recommends --no-install-suggests -y \
    vim inetutils-ping iproute2 curl rsyslog haproxy keepalived && \
    rm -rf /var/lib/apt/lists/* && \
# syslog settings
    sed -i 's/^\(module.*imklog.*\)/# \1/g' /etc/rsyslog.conf && \
# cp stuff
    cp /tmp/entrypoint.sh / && \
    cp /tmp/WELCOME / && \
    mkdir /etc/ssl && cp -r /tmp/ssl/* /etc/ssl && \
    cp -r /tmp/samples/haproxy/* /etc/haproxy && \
    cp -r /tmp/samples/keepalived/* /etc/keepalived && \
# chmod
    chmod +x /entrypoint.sh && \
# clean up
    rm -r /tmp/*

EXPOSE 8080 8443 8090

ENTRYPOINT ["/entrypoint.sh"]

CMD ["/bin/bash"]