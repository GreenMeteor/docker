# HumHub Docker Deployment

This repository contains a complete Docker setup for running a secure, production-ready HumHub instance with automatic backups, caching, and HTTPS support.

## Features

- **HumHub**: Latest version (1.17.2) with PHP 8.2
- **Security**: Hardened containers with minimal privileges and capabilities
- **Database**: MariaDB 10.11 with secure configuration
- **Caching**: Redis for improved performance
- **Web Server**: Nginx as reverse proxy with HTTP/2 and TLS 1.3
- **Backups**: Automated daily backups using Borg
- **Email**: Configurable SMTP relay for notifications
- **Health Checks**: Container health monitoring
- **Volumes**: Persistent data storage for all components

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- At least 2GB of RAM
- 20GB+ of disk space

## Quick Start

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/humhub-docker.git
   cd humhub-docker
   ```

2. Configure environment variables:
   ```bash
   cp .env.example .env
   # Edit .env with your own secure passwords and settings
   ```

3. Start the containers:
   ```bash
   docker-compose up -d
   ```

4. Access your HumHub instance at https://your-server-ip

## Directory Structure

```
/
├── .env                           # Environment variables
├── docker-compose.yml             # Container orchestration
├── mysql/                         # MariaDB configuration
│   ├── my.cnf                     # MySQL server configuration
│   └── init/                      # Initialization scripts
│       └── 01-securemysql.sql     # Security hardening SQL
├── humhub/                        # HumHub application
│   ├── Dockerfile                 # PHP container definition
│   ├── docker-entrypoint.sh       # Initialization script
│   ├── php.ini                    # PHP configuration
│   └── wait-for-it.sh             # Script to wait for DB
├── nginx/                         # Web server
│   ├── Dockerfile                 # Nginx container definition
│   ├── nginx.conf                 # Main configuration
│   ├── conf.d/                    # Site configurations
│   │   └── default.conf           # HumHub site config
│   └── ssl/                       # SSL certificates
│       ├── cert.pem               # SSL certificate
│       └── key.pem                # SSL private key
└── backup/                        # Backup system
    ├── Dockerfile                 # Backup container definition
    ├── config/                    # Backup configuration
    │   └── borg.conf              # Borg settings
    ├── scripts/                   # Backup scripts
    │   └── backup.sh              # Main backup script
    └── repo/                      # Backup repository
        └── .placeholder           # Placeholder for git
```

## Configuration

### Environment Variables

Edit the `.env` file to configure your installation:

| Variable | Description | Default |
|----------|-------------|---------|
| `MYSQL_ROOT_PASSWORD` | MariaDB root password | *random* |
| `MYSQL_PASSWORD` | HumHub database password | *random* |
| `REDIS_PASSWORD` | Redis password | *random* |
| `HUMHUB_ADMIN_EMAIL` | Admin email | admin@example.com |
| `HUMHUB_ADMIN_LOGIN` | Admin username | admin |
| `HUMHUB_ADMIN_PASSWORD` | Admin password | *random* |
| `HUMHUB_SITE_NAME` | Community name | My HumHub Community |
| `HUMHUB_SITE_EMAIL` | System email | noreply@example.com |
| `HUMHUB_MAILER_*` | Email configuration | PHP mail() |
| `BORG_PASSPHRASE` | Backup encryption key | *random* |

### SSL Certificates

For production use, replace the self-signed certificates in `nginx/ssl/` with your own certificates. If you don't provide certificates, self-signed ones will be generated automatically.

For Let's Encrypt support:
1. Use proper domain names in `nginx/conf.d/default.conf`
2. Set up a reverse proxy like Traefik or use Certbot

## Volumes

The setup uses Docker volumes for persistent data:

| Volume | Description |
|--------|-------------|
| `mariadb_data` | Database files |
| `redis_data` | Redis cache data |
| `humhub_data` | Runtime data |
| `humhub_uploads` | User uploads |
| `humhub_modules` | Installed modules |
| `humhub_config` | Configuration files |
| `humhub_themes` | Custom themes |
| `humhub_assets` | Compiled assets |
| `nginx_logs` | Web server logs |

## Backup and Restore

### Manual Backup

You can trigger a manual backup with:

```bash
docker exec humhub-backup /scripts/backup.sh
```

### Restore from Backup

1. Stop the containers:
   ```bash
   docker-compose down
   ```

2. List available backups:
   ```bash
   docker run --rm -v humhub-backup_repo:/repo -e BORG_PASSPHRASE=your_passphrase \
     alpine/borg list /repo
   ```

3. Extract a backup:
   ```bash
   docker run --rm -it \
     -v humhub-backup_repo:/repo \
     -v ./restored_data:/target \
     -e BORG_PASSPHRASE=your_passphrase \
     alpine/borg extract /repo::backup_name
   ```

4. Restore MySQL database:
   ```bash
   docker-compose up -d mariadb
   cat ./restored_data/tmp/mysql_dump.sql | docker exec -i humhub-mariadb \
     mysql -uhumhub -p humhub
   ```

5. Restore other data:
   ```bash
   # Copy the data to the appropriate volumes
   ```

6. Restart containers:
   ```bash
   docker-compose up -d
   ```

## Upgrading HumHub

To upgrade to a newer HumHub version:

1. Update the `HUMHUB_VERSION` in `humhub/Dockerfile`
2. Rebuild the container:
   ```bash
   docker-compose build humhub
   docker-compose up -d humhub
   ```

## Security Considerations

This setup includes several security features:

- Containers run with minimal capabilities
- No privileged containers
- Network isolation
- Resource limits
- Regular security updates
- Data encryption at rest (backups)
- TLS for all connections
- Security headers in Nginx

## Troubleshooting

### Common Issues

**Cannot connect to HumHub:**
- Check if all containers are running: `docker-compose ps`
- Verify network connectivity: `docker-compose logs nginx`
- Ensure ports 80/443 are accessible

**Database connection errors:**
- Check database credentials in `.env`
- Inspect MariaDB logs: `docker-compose logs mariadb`
- Verify the database exists: `docker exec -it humhub-mariadb mysql -u root -p`

**Email not working:**
- Verify SMTP settings in `.env`
- Check mail logs: `docker-compose logs humhub`
- Test mail configuration in HumHub admin panel

### Log Access

View container logs:
```bash
docker-compose logs -f [service_name]
```

Available services: `mariadb`, `redis`, `humhub`, `nginx`, `backup`.

## Performance Tuning

For better performance:

1. Adjust PHP settings in `humhub/php.ini`
2. Optimize MariaDB in `mysql/my.cnf`
3. Tune Nginx worker processes in `nginx/nginx.conf`
4. Consider adding more memory to Redis

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- [HumHub](https://www.humhub.com/) - The social networking software
- [Docker](https://www.docker.com/) - Container platform
- [BorgBackup](https://www.borgbackup.org/) - Deduplicating backup program
- [Nginx](https://nginx.org/) - High-performance web server
- [MariaDB](https://mariadb.org/) - Open source database
- [Redis](https://redis.io/) - In-memory data store
