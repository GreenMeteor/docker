# Use a specific FrankenPHP image with PHP 8.3 and Debian Bookworm variant
FROM dunglas/frankenphp-dev:latest

# Use tini as an entrypoint for better process management
RUN apt-get update && apt-get install -y tini && apt-get clean

# Set the working directory for HumHub
WORKDIR /var/www/html

# Install system dependencies required by PHP extensions and HumHub
RUN apt-get update && apt-get install -y --no-install-recommends \
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
    apache2 \
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
RUN apt-get update && apt-get install -y --no-install-recommends \
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

# Create necessary directories for Apache, Cron, and other dependencies
RUN mkdir -p /var/run/apache2 /var/run/cron /var/www/html/app/config /var/www/html/app/modules /var/www/html/app/protected

# Set ownership for all HumHub files to a non-root user
RUN useradd -m -d /home/humhubuser -s /bin/bash humhubuser && \
    chown -R humhubuser:humhubuser /var/www/html/app /var/run/apache2 /var/run/cron && \
    chmod -R 775 /var/www/html/app

# Copy and set up cron job
COPY crontab /etc/cron.d/humhub-cron
RUN chmod 0644 /etc/cron.d/humhub-cron && crontab /etc/cron.d/humhub-cron

# Expose port 8080 for HTTP access
EXPOSE 8080

# Switch to the non-root user
USER humhubuser

# Use tini as the entry point to manage processes
ENTRYPOINT ["/usr/bin/tini", "--"]

# Start the cron service, Apache server, and FrankenPHP
CMD ["sh", "-c", "service cron start && service apache2 start && frankenphp /var/www/html/app/index.php"]
