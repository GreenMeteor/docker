FROM php:8.2-fpm

ARG HUMHUB_VERSION=1.17.2

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends --no-install-suggests \
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
    file \
    libmagickwand-dev && \
    rm -rf /var/lib/apt/lists/* && \
    docker-php-ext-configure gd --with-freetype --with-jpeg && \
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
COPY php.ini /usr/local/etc/php/conf.d/custom.ini

# Copy wait-for-it script
COPY wait-for-it.sh /usr/local/bin/wait-for-it

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# Make scripts executable
RUN chmod +x /usr/local/bin/wait-for-it /usr/local/bin/docker-entrypoint.sh

# Download and verify HumHub
RUN curl -fSL --retry 5 --retry-delay 5 https://download.humhub.com/downloads/install/humhub-${HUMHUB_VERSION}.zip -o humhub.zip && \
    file humhub.zip | grep -q 'Zip archive data' && \
    unzip humhub.zip -d /tmp/ && \
    rm humhub.zip && \
    mv /tmp/humhub-* /var/www/html && \
    echo "<?php echo 'OK';" > /var/www/html/ping && \
    chmod -R 755 /var/www/html && \
    find /var/www/html -type f -exec chmod 644 {} \; && \
    find /var/www/html -type d -exec chmod 755 {} \; && \
    chmod -R 775 /var/www/html/protected/runtime \
                   /var/www/html/protected/modules \
                   /var/www/html/uploads \
                   /var/www/html/assets && \
    chown -R www-data:www-data /var/www/html && \
    rm -rf /var/www/html/protected/vendor/bower-asset/*/test \
           /var/www/html/protected/vendor/bower-asset/*/tests \
           /var/www/html/protected/vendor/*/test \
           /var/www/html/protected/vendor/*/tests \
           /var/www/html/protected/runtime/logs/*

# Create volume mount points
VOLUME ["/var/www/html/protected/runtime", "/var/www/html/uploads", "/var/www/html/protected/modules", "/var/www/html/protected/config", "/var/www/html/themes"]

# Set working directory
WORKDIR /var/www/html

# Set entrypoint and default command
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["php-fpm"]
