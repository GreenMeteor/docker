FROM php:8.2-fpm

ARG HUMHUB_VERSION=1.17.2

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies (pinned)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libzip-dev=1.9.2-1.2 \
    libfreetype6-dev=2.12.1-6 \
    libjpeg62-turbo-dev=1:2.1.5-2 \
    libpng-dev=1.6.39-2 \
    libicu-dev=72.1-3 \
    libldap2-dev=2.6.3+dfsg-1~deb12u1 \
    libxml2-dev=2.9.14+dfsg-1.3 \
    curl=7.88.1-10+deb12u1 \
    wget=1.21.3-1+b2 \
    unzip=6.0-28 \
    gnupg=2.2.40-1.1 \
    git=1:2.39.2-1.1 \
    libmagickwand-dev=8:6.9.11.60+dfsg-1.5 \
 && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
 && docker-php-ext-install -j"$(nproc)" \
      gd \
      intl \
      mysqli \
      pdo_mysql \
      zip \
      exif \
      opcache \
      ldap \
      xml

# Install and enable PECL extensions
RUN pecl install imagick redis \
 && docker-php-ext-enable imagick redis

# PHP configuration
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

# Download and install HumHub
WORKDIR /tmp
RUN curl -SL https://download.humhub.com/downloads/install/humhub-${HUMHUB_VERSION}.zip -o humhub.zip \
 && unzip humhub.zip -d /tmp/ \
 && rm humhub.zip \
 && mv /tmp/humhub-* /var/www/html \
 && chown -R www-data:www-data /var/www/html

# Copy scripts
COPY wait-for-it.sh /usr/local/bin/wait-for-it
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/wait-for-it /usr/local/bin/docker-entrypoint.sh

# Create healthcheck endpoint
RUN echo "<?php echo 'OK';" > /var/www/html/ping

# Set permissions
RUN chmod -R 755 /var/www/html \
 && find /var/www/html -type f -exec chmod 644 {} \; \
 && find /var/www/html -type d -exec chmod 755 {} \; \
 && chmod -R 775 \
      /var/www/html/protected/runtime \
      /var/www/html/protected/modules \
      /var/www/html/uploads \
      /var/www/html/assets \
 && chown -R www-data:www-data /var/www/html

# Define volumes
VOLUME [ \
  "/var/www/html/protected/runtime", \
  "/var/www/html/uploads", \
  "/var/www/html/protected/modules", \
  "/var/www/html/protected/config", \
  "/var/www/html/themes" \
]

# Clean unneeded test directories
RUN rm -rf \
  /var/www/html/protected/vendor/bower-asset/*/test \
  /var/www/html/protected/vendor/bower-asset/*/tests \
  /var/www/html/protected/vendor/*/test \
  /var/www/html/protected/vendor/*/tests \
  /var/www/html/protected/runtime/logs/*

WORKDIR /var/www/html

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["php-fpm"]
