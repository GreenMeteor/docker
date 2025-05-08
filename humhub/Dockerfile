FROM php:8.2-fpm

ARG HUMHUB_VERSION=1.17.2

# Install system dependencies and clean up
RUN apt-get update && apt-get install -y --no-install-recommends \
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
        libmagickwand-dev && \
    rm -rf /var/lib/apt/lists/*

# Install PHP extensions
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
        xml

# Install PECL extensions
RUN pecl install imagick redis && \
    docker-php-ext-enable imagick redis

# Set recommended PHP.ini settings
RUN echo 'opcache.memory_consumption=128\n' \
         'opcache.interned_strings_buffer=8\n' \
         'opcache.max_accelerated_files=4000\n' \
         'opcache.revalidate_freq=60\n' \
         'opcache.fast_shutdown=1\n' \
         'opcache.enable_cli=1\n' \
         'upload_max_filesize=32M\n' \
         'post_max_size=32M\n' \
         'memory_limit=256M\n' \
         'max_execution_time=120\n' \
         'date.timezone=UTC' \
         > /usr/local/etc/php/conf.d/opcache-recommended.ini

# Download and extract HumHub
WORKDIR /tmp
RUN curl -SL https://download.humhub.com/downloads/install/humhub-${HUMHUB_VERSION}.zip -o humhub.zip && \
    unzip humhub.zip -d /tmp/ && \
    rm humhub.zip && \
    mv /tmp/humhub-* /var/www/html && \
    chown -R www-data:www-data /var/www/html

# Copy scripts and make them executable
COPY wait-for-it.sh docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/wait-for-it /usr/local/bin/docker-entrypoint.sh

# Create simple health check script
RUN echo "<?php echo 'OK';" > /var/www/html/ping

# Set permissions
RUN chmod -R 755 /var/www/html && \
    find /var/www/html -type f -exec chmod 644 {} \; && \
    find /var/www/html -type d -exec chmod 755 {} \; && \
    chmod -R 775 /var/www/html/protected/runtime /var/www/html/protected/modules /var/www/html/uploads /var/www/html/assets && \
    chown -R www-data:www-data /var/www/html

# Volume mount points
VOLUME ["/var/www/html/protected/runtime", "/var/www/html/uploads", "/var/www/html/protected/modules", "/var/www/html/protected/config", "/var/www/html/themes"]

# Clean up unused test files
RUN rm -rf /var/www/html/protected/vendor/bower-asset/*/test \
           /var/www/html/protected/vendor/bower-asset/*/tests \
           /var/www/html/protected/vendor/*/test \
           /var/www/html/protected/vendor/*/tests \
           /var/www/html/protected/runtime/logs/*

# Working directory and startup
WORKDIR /var/www/html
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["php-fpm"]
