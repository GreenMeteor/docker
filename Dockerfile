# Use a specific FrankenPHP image with PHP 8.3 and Debian Bookworm variant
FROM dunglas/frankenphp:1.3-php8.3-bookworm

# Set the working directory for HumHub
WORKDIR /var/www/html

# Install system dependencies required by PHP extensions and HumHub
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    libicu-dev \
    libmagickcore-dev \
    libmagickwand-dev \
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

# Copy HumHub application files into the container
COPY . /var/www/html

# Set proper file permissions for HumHub
RUN chown -R www-data:www-data /var/www/html && chmod -R 775 /var/www/html

# Expose port 8080 for HTTP access
EXPOSE 8080

# Set the entrypoint to start the FrankenPHP web server
CMD ["frankenphp", "/var/www/html/index.php"]
