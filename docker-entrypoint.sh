#!/bin/sh
# Entry point for Docker container to initialize and start services.

# Start cron in the background
echo "Starting cron..."
cron || echo "Cron service already running."

# Check if FrankenPHP should be started and run it
echo "Starting FrankenPHP..."
exec frankenphp run --config /etc/caddy/Caddyfile || echo "::error::FrankenPHP failed to start."
