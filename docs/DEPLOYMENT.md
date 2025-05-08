# Deployment Guide

This guide explains how to deploy the HumHub Docker setup using GitHub Actions for CI/CD.

## Prerequisites

Before you begin, you'll need:

1. A GitHub repository containing your HumHub Docker setup
2. A server with Docker and Docker Compose installed
3. SSH access to your server
4. GitHub repository secrets properly configured

## GitHub Secrets Configuration

Add the following secrets to your GitHub repository:

| Secret Name | Description |
|-------------|-------------|
| `SSH_PRIVATE_KEY` | Private SSH key for accessing your server |
| `DEPLOY_HOST` | Hostname or IP address of your server |
| `DEPLOY_USER` | SSH username for your server |
| `DEPLOY_PATH` | Path on your server where HumHub should be deployed |
| `SLACK_WEBHOOK` | (Optional) Webhook URL for Slack notifications |

## Deployment Methods

### Automatic Deployment on Tag

When you create and push a new tag with the format `v*` (e.g., `v1.0.0`), GitHub Actions will automatically:

1. Build and test your Docker images
2. Deploy them to your production server

```bash
# Example: Create and push a new release tag
git tag v1.0.0
git push origin v1.0.0
```

### Manual Deployment

You can also trigger a deployment manually:

1. Go to the "Actions" tab in your GitHub repository
2. Select the "HumHub Docker CI/CD" workflow
3. Click "Run workflow"
4. Select the branch you want to deploy
5. Set "Deploy to production" to "true"
6. Click "Run workflow"

## Environment Variables

Create a `.env` file on your server with production values:

```
MYSQL_ROOT_PASSWORD=your_secure_root_password
MYSQL_PASSWORD=your_secure_db_password
REDIS_PASSWORD=your_secure_redis_password
HUMHUB_ADMIN_EMAIL=admin@yourdomain.com
HUMHUB_ADMIN_LOGIN=admin
HUMHUB_ADMIN_PASSWORD=your_secure_admin_password
HUMHUB_SITE_NAME=Your HumHub Community
HUMHUB_SITE_EMAIL=noreply@yourdomain.com
HUMHUB_MAILER_TRANSPORT=smtp
HUMHUB_MAILER_HOST=your_smtp_server
HUMHUB_MAILER_PORT=587
HUMHUB_MAILER_USERNAME=your_smtp_username
HUMHUB_MAILER_PASSWORD=your_smtp_password
HUMHUB_MAILER_ENCRYPTION=tls
BORG_PASSPHRASE=your_secure_backup_passphrase
```

## Deployment Process

The deployment process:

1. Connects to your server via SSH
2. Copies all necessary files to the specified deployment path
3. Makes scripts executable
4. Creates a backup of the existing installation (if one exists)
5. Stops the current containers
6. Starts the new containers
7. Verifies the deployment
8. Sends a Slack notification (if configured)

## SSL/TLS Certificates

For production deployments, you should provide proper SSL certificates. You have two options:

### Option 1: Self-managed certificates

1. Place your SSL certificate and private key in `nginx/ssl/`:
   - `nginx/ssl/cert.pem` - Certificate file
   - `nginx/ssl/key.pem` - Private key file

### Option 2: Let's Encrypt with Certbot

1. Install Certbot on your server
2. Obtain certificates for your domain
3. Update the Nginx configuration to use the Let's Encrypt certificates

```bash
# Example for obtaining Let's Encrypt certificates
certbot certonly --standalone -d yourdomain.com -d www.yourdomain.com
```

Then update your `nginx/conf.d/default.conf`:

```
ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
```

## Monitoring the Deployment

You can monitor your deployment in several ways:

1. Check the GitHub Actions logs
2. View the container logs on your server:
   ```bash
   docker-compose logs -f
   ```
3. Monitor container health:
   ```bash
   docker-compose ps
   ```

## Rollback Procedure

If you need to roll back to a previous version:

1. SSH into your server
2. Navigate to your deployment directory
3. Check out the previous version:
   ```bash
   git checkout v1.0.0  # Replace with your previous version
   ```
4. Restart the containers:
   ```bash
   docker-compose down
   docker-compose up -d
   ```

Alternatively, you can restore from a backup:

1. List available backups:
   ```bash
   docker exec humhub-backup borg list /backup/repo
   ```
2. Follow the restore procedure in the main README
