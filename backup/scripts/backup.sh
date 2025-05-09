#!/bin/bash
set -e

# Load configuration
source /etc/borg/borg.conf

# Initialize variables
BACKUP_DATE="$(date +%Y-%m-%d_%H-%M-%S)"
BACKUP_NAME="${BACKUP_PREFIX}_${BACKUP_DATE}"
MYSQL_DUMP_FILE="/tmp/mysql_dump.sql"

echo "Starting backup process: ${BACKUP_NAME}"

# Check if repository exists, if not initialize it
if [ ! -f "${BORG_REPO}/config" ]; then
    echo "Initializing Borg repository..."
    borg init --encryption=repokey "${BORG_REPO}"
fi

# Create MySQL dump
echo "Creating MySQL database dump..."
mysqldump --host="${MYSQL_HOST}" --user="${MYSQL_USER}" \
    --password="${MYSQL_PASSWORD}" "${MYSQL_DATABASE}" \
    ${MYSQL_DUMP_OPTIONS} > "${MYSQL_DUMP_FILE}"

# Create backup
echo "Creating Borg backup archive..."
borg create \
    --verbose \
    --filter AME \
    --list \
    --stats \
    --compression "${BORG_COMPRESSION}" \
    --exclude-caches \
    "${BORG_REPO}::${BACKUP_NAME}" \
    "${BACKUP_SOURCES}" \
    "${MYSQL_DUMP_FILE}"

# Remove MySQL dump file
rm -f "${MYSQL_DUMP_FILE}"

# Prune old backups
echo "Pruning old backups..."
borg prune \
    --list \
    --prefix "${BACKUP_PREFIX}_" \
    "${BORG_RETENTION}" \
    "${BORG_REPO}"

echo "Backup completed successfully"
