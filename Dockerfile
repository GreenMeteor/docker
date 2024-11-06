# Use a specific FrankenPHP image with PHP 8.3 and Debian Bookworm variant
FROM dunglas/frankenphp-dev:latest

# Set the working directory for HumHub
WORKDIR /var/www/html

# Install system dependencies required by PHP extensions, cron, and HumHub
RUN apt-get update && apt-get install -y \
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
RUN apt-get update && apt-get install -y \
    imagemagick \
    graphicsmagick \
    && rm -rf /var/lib/apt/lists/*

# Download the HumHub zip file
RUN curl -L https://download.humhub.com/downloads/install/humhub-1.17.0-beta.1.zip -o humhub.zip

# Create the app/ directory and extract the HumHub zip into it
RUN mkdir -p /var/www/html/app && \
    unzip -q humhub.zip -d humhub_temp && \
    mv humhub_temp/humhub-1.17.0-beta.1/* /var/www/html/app/ && \
    rm -rf humhub_temp humhub.zip

# Set proper file permissions for HumHub
RUN chown -R www-data:www-data /var/www/html/app && chmod -R 775 /var/www/html/app

# Copy and set up cron job
COPY crontab /etc/cron.d/humhub-cron
RUN chmod 0644 /etc/cron.d/humhub-cron && crontab /etc/cron.d/humhub-cron

# Expose port 8080 for HTTP access
EXPOSE 8080

# Start cron service and FrankenPHP web server
CMD service cron start && frankenphp /var/www/html/app/index.php
