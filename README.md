# HumHub Docker Setup with FrankenPHP

This Docker setup uses a **FrankenPHP** image with PHP 8.3 and the **Debian Bookworm** variant to run [HumHub](https://www.humhub.com/), a flexible social network kit. It installs necessary dependencies, PHP extensions, and sets up Apache and cron services within the container.

## Dockerfile Overview

The Dockerfile performs the following main steps:
1. **Sets up system dependencies** for HumHub and PHP.
2. **Installs required PHP extensions** for HumHub functionality.
3. **Downloads and extracts HumHub** into the appropriate directory.
4. **Configures cron** to automate HumHub's scheduled tasks.
5. **Exposes port 8080** to allow HTTP access to HumHub.

## Prerequisites

- **Docker**: Ensure Docker is installed on your system.
- **FrankenPHP image**: This Dockerfile is based on the `dunglas/frankenphp-dev` image with PHP 8.3 and Debian Bookworm.

## Quick Start

1. **Clone this repository**:
    ```bash
    git clone <repository_url>
    cd <repository_directory>
    ```

2. **Build the Docker Image**:
    ```bash
    docker build -t humhub-frankenphp .
    ```

3. **Run the Container**:
    ```bash
    docker run -p 8080:8080 humhub-frankenphp
    ```

4. **Access HumHub**:
   Open [http://localhost:8080](http://localhost:8080) in your browser to access the HumHub installation.

## Customizations

- **Database Configuration**: You’ll need to configure HumHub's database settings during the installation process. Consider running a separate MySQL container for database support, or use an external MySQL database.
- **Cron Configuration**: The Dockerfile includes a cron setup to manage HumHub's scheduled tasks, defined in `crontab` file. Adjust cron timings as needed.
  
## Dockerfile Explanation

### Base Image
```dockerfile
FROM dunglas/frankenphp-dev:latest
```
Uses the latest development version of FrankenPHP with PHP 8.3 and Debian Bookworm.

### Working Directory
```dockerfile
WORKDIR /var/www/html
```
Sets the working directory for HumHub files.

### System Dependencies
```dockerfile
RUN apt-get update && apt-get install -y \
    git unzip curl libpng-dev libjpeg-dev libfreetype6-dev libzip-dev \
    libcurl4-openssl-dev libxml2-dev libicu-dev libmagickcore-dev libmagickwand-dev \
    cron apache2 && rm -rf /var/lib/apt/lists/*
```
Installs system packages needed for HumHub and PHP extensions, along with `cron` and `apache2` for HTTP serving and task scheduling.

### PHP Extensions
```dockerfile
RUN install-php-extensions \
    pdo_mysql gd intl zip curl mbstring xml exif fileinfo \
    && pecl install redis && docker-php-ext-enable redis
```
Installs and enables PHP extensions necessary for HumHub's functionality, including Redis.

### Image and File Processing Tools
```dockerfile
RUN apt-get update && apt-get install -y imagemagick graphicsmagick && rm -rf /var/lib/apt/lists/*
```
Adds `ImageMagick` and `GraphicsMagick` for enhanced image handling.

### HumHub Installation
```dockerfile
RUN curl -L https://download.humhub.com/downloads/install/humhub-1.17.0-beta.1.zip -o humhub.zip
```
Downloads HumHub version `1.17.0-beta.1`.

```dockerfile
RUN mkdir -p /var/www/html/app && \
    unzip -q humhub.zip -d humhub_temp && \
    mv humhub_temp/humhub-1.17.0-beta.1/* /var/www/html/app/ && \
    rm -rf humhub_temp humhub.zip
```
Extracts HumHub into `/var/www/html/app` and removes temporary files.

### Permissions
```dockerfile
RUN chown -R www-data:www-data /var/www/html/app && chmod -R 775 /var/www/html/app
```
Sets proper ownership and permissions for HumHub files.

### Cron Setup
```dockerfile
COPY crontab /etc/cron.d/humhub-cron
RUN chmod 0644 /etc/cron.d/humhub-cron && crontab /etc/cron.d/humhub-cron
```
Copies the cron configuration file and enables it to run scheduled tasks for HumHub.

### Exposed Port and CMD
```dockerfile
EXPOSE 8080
CMD service cron start && service apache2 start && frankenphp /var/www/html/app/index.php
```
- **EXPOSE 8080**: Opens port 8080 for HTTP traffic.
- **CMD**: Starts cron, Apache, and FrankenPHP to serve HumHub.

## Support

For questions or support, please refer to the [HumHub Documentation](https://docs.humhub.com/) or the [FrankenPHP Documentation](https://frankenphp.dev/docs).

## Donation

If you're using our Dockerfile and enjoy it, please thank about contributing or [donating](https://donate.stripe.com/7sI6qF2831wB36M5kz) it really helps us continue the development process!
