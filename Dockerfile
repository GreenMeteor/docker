# Build stage
FROM dunglas/frankenphp-dev:latest AS builder

# Build arguments for versioning and cache busting
ARG BUILD_DATE
ARG VCS_REF
ARG HUMHUB_VERSION=1.17.0-beta.1

# Labels for better image management and tracking
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vendor="HumHub" \
      org.label-schema.version=$HUMHUB_VERSION \
      org.label-schema.schema-version="1.0" \
      org.opencontainers.image.created=$BUILD_DATE \
      org.opencontainers.image.revision=$VCS_REF \
      security.privileged="false"

# Set the working directory
WORKDIR /app

# Install build dependencies - combining all apt-get commands to optimize layers
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    unzip \
    curl \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    libicu-dev \
    libmagickcore-dev \
    libmagickwand-dev \
    imagemagick \
    graphicsmagick \
    cron \
    tini \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions using a single layer
RUN install-php-extensions \
    pdo_mysql \
    gd \
    intl \
    zip \
    curl \
    mbstring \
    xml \
    exif \
    fileinfo \
    opcache \
    && pecl install redis \
    && docker-php-ext-enable redis opcache

# Download and extract HumHub
RUN curl -L "https://download.humhub.com/downloads/install/humhub-${HUMHUB_VERSION}.zip" -o humhub.zip && \
    unzip -q humhub.zip -d . && \
    mv "humhub-${HUMHUB_VERSION}"/* . && \
    rm -rf "humhub-${HUMHUB_VERSION}" humhub.zip

# Create necessary scripts
COPY --chmod=755 <<EOF /usr/local/bin/humhub-cron.sh
#!/bin/sh
php /app/protected/yii queue/run >> /var/log/humhub/cron.log 2>&1
php /app/protected/yii cron/run >> /var/log/humhub/cron.log 2>&1
EOF

COPY --chmod=755 <<EOF /usr/local/bin/docker-healthcheck.sh
#!/bin/sh
if curl -sfI http://localhost/ping >/dev/null; then
    # Check if queue is processing
    if php /app/protected/yii queue/info | grep -q "waiting: 0"; then
        exit 0
    fi
    exit 1
fi
exit 1
EOF

COPY --chmod=755 <<EOF /usr/local/bin/docker-entrypoint.sh
#!/bin/sh
set -e

# Create log directory if it doesn't exist
mkdir -p /var/log/humhub
chown -R humhub:humhub /var/log/humhub

# Start cron in the background
cron

# Apply any pending migrations
php /app/protected/yii migrate/up --interactive=0
php /app/protected/yii module/update-all --interactive=0

# Start FrankenPHP
exec frankenphp run --config /etc/caddy/Caddyfile
EOF

# Final stage
FROM dunglas/frankenphp:1.3.0

# Copy build arguments to final stage
ARG BUILD_DATE
ARG VCS_REF
ARG HUMHUB_VERSION

# Copy labels from builder
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vendor="HumHub" \
      org.label-schema.version=$HUMHUB_VERSION

# Install runtime dependencies only
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    tini \
    cron \
    libmagickcore-dev \
    libmagickwand-dev \
    imagemagick \
    && rm -rf /var/lib/apt/lists/*

# Set up non-root user with specific UID/GID
RUN addgroup --system --gid 1001 humhub && \
    adduser --system --uid 1001 --gid 1001 --home /home/humhub --shell /bin/bash humhub

# Set up directories and permissions
WORKDIR /app
RUN mkdir -p /var/log/humhub && \
    chown -R humhub:humhub /var/log/humhub

# Copy application from builder
COPY --from=builder --chown=humhub:humhub /app /app
COPY --from=builder /usr/local/bin/humhub-cron.sh /usr/local/bin/
COPY --from=builder /usr/local/bin/docker-healthcheck.sh /usr/local/bin/
COPY --from=builder /usr/local/bin/docker-entrypoint.sh /usr/local/bin/

# Set up cron
RUN printf '*/5 * * * * /usr/local/bin/humhub-cron.sh\n' > /etc/cron.d/humhub && \
    chmod 0644 /etc/cron.d/humhub && \
    crontab -u humhub /etc/cron.d/humhub

# Copy the FrankenPHP configuration
COPY --chown=humhub:humhub Caddyfile /etc/caddy/Caddyfile

# Set proper permissions
RUN chmod -R 755 /app && \
    chmod -R 775 /app/protected/runtime /app/protected/config /app/uploads

# Add security headers
ENV PHP_OPCACHE_ENABLE=1 \
    PHP_OPCACHE_REVALIDATE_FREQ=0 \
    PHP_OPCACHE_VALIDATE_TIMESTAMPS=0 \
    PHP_OPCACHE_MAX_ACCELERATED_FILES=10000 \
    PHP_OPCACHE_MEMORY_CONSUMPTION=192 \
    PHP_OPCACHE_MAX_WASTED_PERCENTAGE=10

# Set up volumes
VOLUME ["/app/protected/config", "/app/protected/runtime", "/app/uploads"]

# Expose ports
EXPOSE 80 443

# Set up healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD ["/usr/local/bin/docker-healthcheck.sh"]

# Switch to non-root user
USER humhub

# Use tini as init process
ENTRYPOINT ["/usr/bin/tini", "--"]

# Set the default command
CMD ["/usr/local/bin/docker-entrypoint.sh"]
