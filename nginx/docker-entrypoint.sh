#!/bin/sh
set -e

# Generate self-signed certificate if not present
if [ ! -f /etc/nginx/ssl/cert.pem ] || [ ! -f /etc/nginx/ssl/key.pem ]; then
    mkdir -p /etc/nginx/ssl
    echo "Generating self-signed certificate..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/key.pem \
        -out /etc/nginx/ssl/cert.pem \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
    chmod 400 /etc/nginx/ssl/key.pem
fi

# Execute the original entrypoint
exec nginx -g "daemon off;"
