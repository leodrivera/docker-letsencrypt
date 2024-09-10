# Base image
FROM alpine:latest

# Maintainer information
LABEL maintainer="Maksim Stojkovic <https://github.com/maksimstojkovic>" \
      org.label-schema.vcs-url="https://github.com/maksimstojkovic/docker-letsencrypt"

# Install tools required
RUN apk --no-cache add bash certbot curl openssl

# Copy scripts
WORKDIR /scripts
COPY ./scripts /scripts
RUN chmod -R +x /scripts

# Image starting command
CMD ["/bin/bash", "/scripts/start.sh"]
