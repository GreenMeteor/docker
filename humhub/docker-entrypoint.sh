#!/bin/bash
set -eo pipefail

# Wait for database to be ready
wait-for-it -t 60 ${HUMHUB_DB_HOST}:3306

# Function to handle the HumHub configuration
configure_humhub() {

    if [ ! -f "/var/www/html/protected/config/dynamic.php" ]; then
        echo "Creating initial dynamic.php configuration..."
        cat > /var/www/html/protected/config/dynamic.php <<EOL
<?php
return [
    'components' => [
        'db' => [
            'class' => 'yii\\db\\Connection',
            'dsn' => 'mysql:host=${HUMHUB_DB_HOST};dbname=${HUMHUB_DB_NAME}',
            'username' => '${HUMHUB_DB_USER}',
            'password' => '${HUMHUB_DB_PASSWORD}',
            'charset' => 'utf8mb4',
            'enableSchemaCache' => true,
        ],
EOL

        if [ -n "${HUMHUB_REDIS_HOSTNAME}" ]; then
            cat >> /var/www/html/protected/config/dynamic.php <<EOL
        'cache' => [
            'class' => 'yii\\redis\\Cache',
            'redis' => [
                'hostname' => '${HUMHUB_REDIS_HOSTNAME}',
                'port' => ${HUMHUB_REDIS_PORT},
                'password' => '${HUMHUB_REDIS_PASSWORD}',
                'database' => 0,
            ],
        ],
        'queue' => [
            'class' => 'humhub\\modules\\queue\\driver\\Redis',
            'redis' => [
                'hostname' => '${HUMHUB_REDIS_HOSTNAME}',
                'port' => ${HUMHUB_REDIS_PORT},
                'password' => '${HUMHUB_REDIS_PASSWORD}',
                'database' => 1,
            ],
        ],
EOL
        fi

        if [ -n "${HUMHUB_MAILER_HOST}" ]; then
            cat >> /var/www/html/protected/config/dynamic.php <<EOL
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
EOL
        fi

        cat >> /var/www/html/protected/config/dynamic.php <<EOL
        'urlManager' => [
            'showScriptName' => false,
            'enablePrettyUrl' => true,
        ],
    ],
    'params' => [
        'installed' => false,
    ],
];
EOL

        chown www-data:www-data /var/www/html/protected/config/dynamic.php
        chmod 644 /var/www/html/protected/config/dynamic.php
    fi

    chmod -R 775 /var/www/html/protected/runtime
    chmod -R 775 /var/www/html/protected/modules
    chmod -R 775 /var/www/html/uploads
    chmod -R 775 /var/www/html/assets
    chown -R www-data:www-data /var/www/html/protected/runtime
    chown -R www-data:www-data /var/www/html/protected/modules
    chown -R www-data:www-data /var/www/html/uploads
    chown -R www-data:www-data /var/www/html/assets
    chown -R www-data:www-data /var/www/html/protected/config

    if [ -n "${HUMHUB_ADMIN_EMAIL}" ] && [ -n "${HUMHUB_ADMIN_LOGIN}" ] && [ -n "${HUMHUB_ADMIN_PASSWORD}" ] && [ -n "${HUMHUB_SITE_NAME}" ] && [ -n "${HUMHUB_SITE_EMAIL}" ]; then
        if grep -q "'installed' => false" /var/www/html/protected/config/dynamic.php 2>/dev/null || ! grep -q "'installed' => true" /var/www/html/protected/config/dynamic.php 2>/dev/null; then
            echo "Running automatic HumHub setup..."

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

            echo "HumHub installation completed."
        else
            echo "HumHub already installed, skipping setup."
        fi
    fi

    echo "Applying any pending migrations..."
    php /var/www/html/protected/yii migrate/up --includeModuleMigrations=1 --interactive=0
}

configure_humhub

exec "$@"
