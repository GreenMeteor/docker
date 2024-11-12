# Use the development version of FrankenPHP
FROM dunglas/frankenphp-dev:latest

# Use tini as an entrypoint for better process management
RUN apt-get update && \
    apt-get install -y --no-install-recommends tini && \
    rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Install system dependencies including cron
RUN apt-get update && \
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
    cron \
    && rm -rf /var/lib/apt/lists/*

# Install the necessary PHP extensions for HumHub
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
    && pecl install redis \
    && docker-php-ext-enable redis

# Optional: Install ImageMagick and GraphicsMagick for better image processing
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    imagemagick \
    graphicsmagick \
    && rm -rf /var/lib/apt/lists/*

# Download and extract HumHub
RUN curl -L https://download.humhub.com/downloads/install/humhub-1.17.0-beta.1.zip -o humhub.zip && \
    unzip -q humhub.zip -d . && \
    mv humhub-1.17.0-beta.1/* . && \
    rm -rf humhub-1.17.0-beta.1 humhub.zip

# Create a script to run HumHub cron jobs
RUN echo '#!/bin/sh\n\
php /app/protected/yii queue/run > /dev/null 2>&1\n\
php /app/protected/yii cron/run > /dev/null 2>&1\n\
' > /usr/local/bin/humhub-cron.sh && \
    chmod +x /usr/local/bin/humhub-cron.sh

# Set up the crontab for HumHub
RUN echo '*/5 * * * * /usr/local/bin/humhub-cron.sh' > /etc/cron.d/humhub && \
    chmod 0644 /etc/cron.d/humhub && \
    crontab /etc/cron.d/humhub

# Create an entrypoint script
RUN echo '#!/bin/sh\n\
# Start cron in the background\n\
cron\n\
\n\
# Start FrankenPHP\n\
exec frankenphp run --config /etc/caddy/Caddyfile\n\
' > /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/docker-entrypoint.sh

# Set up non-root user
RUN useradd -m -d /home/humhubuser -s /bin/bash humhubuser && \
    chown -R humhubuser:humhubuser /app && \
    chmod -R 775 /app

# Make sure humhubuser can write to the cron job output
RUN touch /var/log/cron.log && \
    chown humhubuser:humhubuser /var/log/cron.log

# Copy the FrankenPHP configuration
COPY Caddyfile /etc/caddy/Caddyfile

# Expose port 80 and 443 for HTTP/HTTPS access
EXPOSE 80 443

# Use tini as the init process
ENTRYPOINT ["/usr/bin/tini", "--"]

# Run our entrypoint script
CMD ["/usr/local/bin/docker-entrypoint.sh"]
