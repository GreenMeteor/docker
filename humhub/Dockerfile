FROM php:8.2-fpm

ARG HUMHUB_VERSION=1.17.2

# Install dependencies
RUN apt-get update && apt-get install -y \
    libzip-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libicu-dev \
    libldap2-dev \
    libxml2-dev \
    curl \
    wget \
    unzip \
    gnupg \
    git \
    libmagickwand-dev \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ && \
    docker-php-ext-install -j$(nproc) \
    gd \
    intl \
    mysqli \
    pdo_mysql \
    zip \
    exif \
    opcache \
    ldap \
    xml

# Install ImageMagick extension
RUN pecl install imagick && \
    docker-php-ext-enable imagick

# Install Redis extension
RUN pecl install redis && \
    docker-php-ext-enable redis

# Set recommended PHP.ini settings
RUN { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=60'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.enable_cli=1'; \
    echo 'upload_max_filesize=32M'; \
    echo 'post_max_size=32M'; \
    echo 'memory_limit=256M'; \
    echo 'max_execution_time=120'; \
    echo 'date.timezone=UTC'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini

# Download and verify HumHub
WORKDIR /tmp
RUN curl -SL https://download.humhub.com/downloads/install/humhub-${HUMHUB_VERSION}.zip -o humhub.zip && \
    unzip humhub.zip -d /tmp/ && \
    rm humhub.zip && \
    mv /tmp/humhub-* /var/www/html && \
    chown -R www-data:www-data /var/www/html

# Set up wait-for script to ensure database is ready before app starts
COPY wait-for-it.sh /usr/local/bin/wait-for-it
RUN chmod +x /usr/local/bin/wait-for-it

# Copy custom initialization script
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Create health check script
RUN echo "<?php echo 'OK';" > /var/www/html/ping

# Set up proper directory permissions
RUN chmod -R 755 /var/www/html && \
    find /var/www/html -type f -exec chmod 644 {} \; && \
    find /var/www/html -type d -exec chmod 755 {} \; && \
    chmod -R 775 /var/www/html/protected/runtime && \
    chmod -R 775 /var/www/html/protected/modules && \
    chmod -R 775 /var/www/html/uploads && \
    chmod -R 775 /var/www/html/assets && \
    chown -R www-data:www-data /var/www/html

# Create volume mount points
VOLUME ["/var/www/html/protected/runtime", "/var/www/html/uploads", "/var/www/html/protected/modules", "/var/www/html/protected/config", "/var/www/html/themes"]

# Set up security hardening
RUN rm -rf /var/www/html/protected/vendor/bower-asset/*/test && \
    rm -rf /var/www/html/protected/vendor/bower-asset/*/tests && \
    rm -rf /var/www/html/protected/vendor/*/test && \
    rm -rf /var/www/html/protected/vendor/*/tests && \
    rm -rf /var/www/html/protected/runtime/logs/*

# Set working directory
WORKDIR /var/www/html

# Set entrypoint
ENTRYPOINT ["docker-entrypoint.sh"]

# Default command
CMD ["php-fpm"]
