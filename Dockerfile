# Borrowing the latest-sidecar image to extract the datacollector binaries
FROM lacework/datacollector:latest-sidecar
RUN gunzip -c /var/lib/lacework-backup/*/datacollector-musl.gz > datacollector_alpine
RUN gunzip -c /var/lib/lacework-backup/*/datacollector.gz > datacollector_linux

# Build a fresh alpine image with just the files we need
FROM alpine:latest
RUN rm -rf /var/cache/apk/*

RUN mkdir -p /shared
WORKDIR /shared/

COPY --from=0 /etc/ssl/certs/ca-certificates.crt .
COPY --from=0 /datacollector_alpine .
COPY --from=0 /datacollector_linux .

COPY lacework.sh lacework.sh
RUN chmod +x ./lacework.sh

VOLUME /shared
