#!/bin/bash
set -eo pipefail

# Wait for database to be ready
wait-for-it -t 60 ${HUMHUB_DB_HOST}:3306

# Function to handle the HumHub configuration
configure_humhub() {
    # Create common.php if it doesn't exist
    if [ ! -f "/var/www/html/protected/config/common.php" ]; then
        echo "Creating initial common.php configuration..."
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
            'class' => 'humhub\modules\queue\driver\Redis',
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

    # Create dynamic.php if it doesn't exist
    if [ ! -f "/var/www/html/protected/config/dynamic.php" ]; then
        echo "Creating initial dynamic.php configuration..."
        cat > /var/www/html/protected/config/dynamic.php <<EOL
<?php
return [];
EOL
        chown www-data:www-data /var/www/html/protected/config/dynamic.php
        chmod 644 /var/www/html/protected/config/dynamic.php
    fi

    # Ensure proper directory permissions
    chmod -R 775 /var/www/html/protected/runtime
    chmod -R 775 /var/www/html/protected/modules
    chmod -R 775 /var/www/html/uploads
    chmod -R 775 /var/www/html/assets
    chown -R www-data:www-data /var/www/html/protected/runtime
    chown -R www-data:www-data /var/www/html/protected/modules
    chown -R www-data:www-data /var/www/html/uploads
    chown -R www-data:www-data /var/www/html/assets
    chown -R www-data:www-data /var/www/html/protected/config

    # Run automatic setup if we have admin credentials
    if [ -n "${HUMHUB_ADMIN_EMAIL}" ] && [ -n "${HUMHUB_ADMIN_LOGIN}" ] && [ -n "${HUMHUB_ADMIN_PASSWORD}" ] && [ -n "${HUMHUB_SITE_NAME}" ] && [ -n "${HUMHUB_SITE_EMAIL}" ]; then
        # Check if HumHub is already installed
        if grep -q '"installed":false' /var/www/html/protected/config/dynamic.php 2>/dev/null || ! grep -q '"installed":true' /var/www/html/protected/config/dynamic.php 2>/dev/null; then
            echo "Running automatic HumHub setup..."

            # Setup database, apply migrations, and initialize with admin user
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

    # Apply any pending migrations
    echo "Applying any pending migrations..."
    php /var/www/html/protected/yii migrate/up --includeModuleMigrations=1 --interactive=0
}

# Configure HumHub
configure_humhub

# Execute the main command
exec "$@"
