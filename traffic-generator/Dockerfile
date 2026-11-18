FROM alpine:3.22

RUN apk add --no-cache ca-certificates curl \
    && adduser -D -H -s /sbin/nologin runner

COPY traffic-generator.sh /usr/local/bin/traffic-generator
RUN chmod 755 /usr/local/bin/traffic-generator

USER runner

ENTRYPOINT ["/usr/local/bin/traffic-generator"]
