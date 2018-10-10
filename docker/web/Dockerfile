FROM nginx

LABEL maintainer="morningspace@yahoo.com"

COPY ./conf ./docker/web/entrypoint.sh /tmp/

RUN \
# install packages
    apt-get update && \
    apt-get install --no-install-recommends --no-install-suggests -y \
    vim && \
    rm -rf /var/lib/apt/lists/* && \
# cp stuff
    cp /tmp/entrypoint.sh / && \
    cp -r /tmp/samples/nginx/* /etc/nginx/conf.d/ && \
    cp -r /tmp/ssl/* /etc/ssl/ && \
# chmod
    chmod +x /entrypoint.sh && \
# clean up
    rm -r /tmp/*

EXPOSE 80 443

ENTRYPOINT ["/entrypoint.sh"]

CMD ["/bin/bash"]
