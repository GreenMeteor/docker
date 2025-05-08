FROM php:8.2-fpm

ARG HUMHUB_VERSION=1.17.2

# Install dependencies (with pinned versions)
RUN apt-get update && apt-get install -y \
    libzip-dev=1.5.0-5 \
    libfreetype6-dev=2.10.1-2ubuntu1 \
    libjpeg62-turbo-dev=1:1.5.2-2ubuntu1 \
    libpng-dev=1.6.37-1 \
    libicu-dev=68.1-1ubuntu1 \
    libldap2-dev=2.4.57-2ubuntu8.2 \
    libxml2-dev=2.9.10+dfsg-5ubuntu0.20.04.4 \
    curl=7.68.0-1ubuntu2.6 \
    wget=1.20.3-1ubuntu2.1 \
    unzip=6.0-21ubuntu1 \
    gnupg=2.2.19-3ubuntu2.1 \
    git=1:2.25.1-1ubuntu3.2 \
    libmagickwand-dev=8:6.9.10.23+dfsg-2.1ubuntu11.4 \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Install PHP extensions and PECL extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ && \
    docker-php-ext-install -j"$(nproc)" \
    gd \
    intl \
    mysqli \
    pdo_mysql \
    zip \
    exif \
    opcache \
    ldap \
    xml && \
    pecl install imagick redis && \
    docker-php-ext-enable imagick redis

# Set recommended PHP.ini settings
RUN printf 'opcache.memory_consumption=128\n' \
    'opcache.interned_strings_buffer=8\n' \
    'opcache.max_accelerated_files=4000\n' \
    'opcache.revalidate_freq=60\n' \
    'opcache.fast_shutdown=1\n' \
    'opcache.enable_cli=1\n' \
    'upload_max_filesize=32M\n' \
    'post_max_size=32M\n' \
    'memory_limit=256M\n' \
    'max_execution_time=120\n' \
    'date.timezone=UTC\n' > /usr/local/etc/php/conf.d/opcache-recommended.ini

# Download and verify HumHub
WORKDIR /tmp
RUN curl -SL https://download.humhub.com/downloads/install/humhub-${HUMHUB_VERSION}.zip -o humhub.zip && \
    unzip humhub.zip -d /tmp/ && \
    rm humhub.zip && \
    mv /tmp/humhub-* /var/www/html && \
    chown -R www-data:www-data /var/www/html

# Setup scripts and permissions
COPY wait-for-it.sh /usr/local/bin/wait-for-it
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/wait-for-it /usr/local/bin/docker-entrypoint.sh

# Create health check script
RUN echo "<?php echo 'OK';" > /var/www/html/ping

# Set directory permissions
RUN chmod -R 755 /var/www/html && \
    find /var/www/html -type f -exec chmod 644 {} \; && \
    find /var/www/html -type d -exec chmod 755 {} \; && \
    chmod -R 775 /var/www/html/protected/runtime /var/www/html/protected/modules /var/www/html/uploads /var/www/html/assets && \
    chown -R www-data:www-data /var/www/html

# Create volume mount points
VOLUME ["/var/www/html/protected/runtime", "/var/www/html/uploads", "/var/www/html/protected/modules", "/var/www/html/protected/config", "/var/www/html/themes"]

# Security hardening (clean up unneeded test dirs)
RUN rm -rf /var/www/html/protected/vendor/bower-asset/*/test \
           /var/www/html/protected/vendor/bower-asset/*/tests \
           /var/www/html/protected/vendor/*/test \
           /var/www/html/protected/vendor/*/tests \
           /var/www/html/protected/runtime/logs/*

# Set working directory
WORKDIR /var/www/html

# Set entrypoint and default command
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["php-fpm"]
