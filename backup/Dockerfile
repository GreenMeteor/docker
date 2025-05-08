FROM alpine:3.17

# Install dependencies
RUN apk add --no-cache \
    borgbackup \
    mariadb-client \
    bash \
    curl \
    ca-certificates \
    tzdata \
    && rm -rf /var/cache/apk/*

# Create necessary directories
RUN mkdir -p /backup/repo /backup/source /etc/borg /scripts

# Install cron
RUN apk add --no-cache dcron

# Copy scripts and make them executable
COPY scripts/backup.sh /scripts/
RUN chmod +x /scripts/backup.sh

# Setup cron job to run backup script
RUN echo "0 2 * * * /scripts/backup.sh >> /var/log/backup.log 2>&1" > /etc/crontabs/root

# Create entrypoint script
RUN echo '#!/bin/sh' > /entrypoint.sh && \
    echo 'crond -f &' >> /entrypoint.sh && \
    echo 'exec "$@"' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

VOLUME ["/backup/repo", "/backup/source", "/etc/borg"]

ENTRYPOINT ["/entrypoint.sh"]
CMD ["sh", "-c", "echo 'Backup service running...' && tail -f /dev/null"]
