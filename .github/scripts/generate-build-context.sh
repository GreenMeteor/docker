#!/bin/bash
set -euo pipefail

echo "Generating Docker build context..."

# Create necessary directories
mkdir -p humhub nginx backup/scripts

# --- PHP.ini ---
cat > humhub/php.ini <<EOF
[PHP]
expose_php = Off
max_execution_time = 120
max_input_time = 120
memory_limit = 256M
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
display_errors = Off
log_errors = On
error_log = /proc/self/fd/2
post_max_size = 32M
file_uploads = On
upload_max_filesize = 32M
max_file_uploads = 20
allow_url_fopen = On
allow_url_include = Off
default_socket_timeout = 60
date.timezone = UTC
session.cookie_httponly = 1
session.use_strict_mode = 1
session.use_cookies = 1
session.use_only_cookies = 1
session.cookie_secure = 1
session.cookie_samesite = "Lax"
session.gc_maxlifetime = 1440
opcache.memory_consumption = 128
opcache.interned_strings_buffer = 8
opcache.max_accelerated_files = 4000
opcache.revalidate_freq = 60
opcache.fast_shutdown = 1
opcache.enable_cli = 1
realpath_cache_size = 4096k
realpath_cache_ttl = 600
disable_functions = exec,passthru,shell_exec,system,proc_open,popen,curl_multi_exec,parse_ini_file,show_source
EOF

# --- Dockerfile for HumHub ---
cat > humhub/Dockerfile <<EOF
FROM php:8.2-fpm

ARG HUMHUB_VERSION=1.17.2

RUN apt-get update && apt-get install -y \\
    libzip-dev libfreetype6-dev libjpeg62-turbo-dev libpng-dev \\
    libicu-dev libldap2-dev libxml2-dev curl wget unzip gnupg git \\
    libmagickwand-dev --no-install-recommends && \\
    rm -rf /var/lib/apt/lists/* && \\
    docker-php-ext-configure gd --with-freetype --with-jpeg && \\
    docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ && \\
    docker-php-ext-install -j"\$(nproc)" gd intl mysqli pdo_mysql zip exif opcache ldap xml && \\
    pecl install imagick redis && \\
    docker-php-ext-enable imagick redis

COPY php.ini /usr/local/etc/php/conf.d/custom.ini

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY wait-for-it.sh /usr/local/bin/wait-for-it

RUN chmod +x /usr/local/bin/wait-for-it /usr/local/bin/docker-entrypoint.sh

RUN curl -SL https://download.humhub.com/downloads/install/humhub-\${HUMHUB_VERSION}.zip -o humhub.zip && \\
    unzip humhub.zip -d /tmp/ && \\
    rm humhub.zip && \\
    mv /tmp/humhub-* /var/www/html && \\
    echo "<?php echo 'OK';" > /var/www/html/ping && \\
    chmod -R 755 /var/www/html && \\
    find /var/www/html -type f -exec chmod 644 {} \\; && \\
    find /var/www/html -type d -exec chmod 755 {} \\; && \\
    chmod -R 775 /var/www/html/protected/runtime /var/www/html/protected/modules /var/www/html/uploads /var/www/html/assets && \\
    chown -R www-data:www-data /var/www/html && \\
    rm -rf /var/www/html/protected/vendor/bower-asset/*/test \\
           /var/www/html/protected/vendor/*/tests \\
           /var/www/html/protected/runtime/logs/*

VOLUME ["/var/www/html/protected/runtime", "/var/www/html/uploads", "/var/www/html/protected/modules", "/var/www/html/protected/config", "/var/www/html/themes"]

WORKDIR /var/www/html

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["php-fpm"]
EOF

# --- docker-entrypoint.sh ---
cat > humhub/docker-entrypoint.sh <<'EOF'
#!/bin/bash
set -eo pipefail

# Wait for DB
wait-for-it -t 60 ${HUMHUB_DB_HOST}:3306

# Create config files if needed
if [ ! -f "/var/www/html/protected/config/common.php" ]; then
    echo "Creating common.php..."
    cat > /var/www/html/protected/config/common.php <<EOL
<?php
return [
    'components' => [
        'db' => [
            'dsn' => 'mysql:host=${HUMHUB_DB_HOST};dbname=${HUMHUB_DB_NAME}',
            'username' => '${HUMHUB_DB_USER}',
            'password' => '${HUMHUB_DB_PASSWORD}',
            'charset' => 'utf8mb4',
            'enableSchemaCache' => true,
        ],
        'cache' => [
            'class' => '${HUMHUB_CACHE_CLASS}',
            'hostname' => '${HUMHUB_REDIS_HOSTNAME}',
            'port' => ${HUMHUB_REDIS_PORT},
            'password' => '${HUMHUB_REDIS_PASSWORD}',
            'database' => 0,
        ],
        'mailer' => [
            'transport' => [
                'class' => 'Swift_SmtpTransport',
                'host' => '${HUMHUB_MAILER_HOST}',
                'username' => '${HUMHUB_MAILER_USERNAME}',
                'password' => '${HUMHUB_MAILER_PASSWORD}',
                'port' => ${HUMHUB_MAILER_PORT},
                'encryption' => '${HUMHUB_MAILER_ENCRYPTION}',
            ],
        ],
        'urlManager' => [
            'showScriptName' => false,
            'enablePrettyUrl' => true,
        ],
        'formatter' => [
            'defaultTimeZone' => 'UTC',
        ],
        'queue' => [
            'class' => 'humhub\\modules\\queue\\driver\\Redis',
            'hostname' => '${HUMHUB_REDIS_HOSTNAME}',
            'port' => ${HUMHUB_REDIS_PORT},
            'password' => '${HUMHUB_REDIS_PASSWORD}',
            'database' => 1,
        ],
    ],
    'params' => [
        'installed' => false,
        'installationId' => '',
        'dynamic' => [],
    ],
];
EOL
fi

if [ ! -f "/var/www/html/protected/config/dynamic.php" ]; then
    echo "<?php return [];" > /var/www/html/protected/config/dynamic.php
    chown www-data:www-data /var/www/html/protected/config/dynamic.php
    chmod 644 /var/www/html/protected/config/dynamic.php
fi

chmod -R 775 /var/www/html/{protected/runtime,protected/modules,uploads,assets}
chown -R www-data:www-data /var/www/html/{protected/runtime,protected/modules,uploads,assets,protected/config}

# Auto install if ENV present
if [ -n "${HUMHUB_ADMIN_EMAIL}" ] && [ -n "${HUMHUB_ADMIN_LOGIN}" ] && [ -n "${HUMHUB_ADMIN_PASSWORD}" ] && [ -n "${HUMHUB_SITE_NAME}" ] && [ -n "${HUMHUB_SITE_EMAIL}" ]; then
    if grep -q '"installed":false' /var/www/html/protected/config/dynamic.php 2>/dev/null || ! grep -q '"installed":true' /var/www/html/protected/config/dynamic.php 2>/dev/null; then
        echo "Auto-installing HumHub..."
        php /var/www/html/protected/yii installer/auto-install \
            --db-host="${HUMHUB_DB_HOST}" \
            --db-name="${HUMHUB_DB_NAME}" \
            --db-username="${HUMHUB_DB_USER}" \
            --db-password="${HUMHUB_DB_PASSWORD}" \
            --admin-email="${HUMHUB_ADMIN_EMAIL}" \
            --admin-username="${HUMHUB_ADMIN_LOGIN}" \
            --admin-password="${HUMHUB_ADMIN_PASSWORD}" \
            --name="${HUMHUB_SITE_NAME}" \
            --email="${HUMHUB_SITE_EMAIL}"
    fi
fi

php /var/www/html/protected/yii migrate/up --includeModuleMigrations=1 --interactive=0

exec "$@"
EOF
chmod +x humhub/docker-entrypoint.sh

# --- wait-for-it.sh ---
curl -fsSL https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh -o humhub/wait-for-it.sh
chmod +x humhub/wait-for-it.sh

# --- nginx ---
cat > nginx/Dockerfile <<EOF
FROM nginx:stable-alpine
COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
EOF

cat > nginx/docker-entrypoint.sh <<EOF
#!/bin/sh
set -e
exec nginx -g "daemon off;"
EOF
chmod +x nginx/docker-entrypoint.sh

# --- backup ---
cat > backup/scripts/backup.sh <<EOF
#!/bin/bash
set -e
echo "Running backup..."
mysqldump -h\$MYSQL_HOST -u\$MYSQL_USER -p\$MYSQL_PASSWORD \$MYSQL_DATABASE > /backup/source/db_backup.sql
borg create --stats --compression lz4 /backup/repo::\$(date +%Y-%m-%d_%H-%M-%S) /backup/source
echo "Backup completed successfully!"
EOF
chmod +x backup/scripts/backup.sh

cat > backup/Dockerfile <<EOF
FROM alpine:3.17
RUN apk add --no-cache borgbackup mariadb-client bash
VOLUME ["/backup"]
COPY scripts/backup.sh /usr/local/bin/backup.sh
ENTRYPOINT ["backup.sh"]
EOF

echo "Build context generated successfully."
