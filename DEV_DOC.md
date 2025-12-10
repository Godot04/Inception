# Developer Documentation

This document provides technical guidance for developers who want to understand, modify, or extend the Inception project.

---

## Setting Up the Environment from Scratch

### Prerequisites

#### Required Software

| Software | Version | Installation (Debian/Ubuntu) |
|----------|---------|------------------------------|
| Docker | 20.10+ | `sudo apt install docker.io` |
| Docker Compose | v2+ | Included with Docker or `sudo apt install docker-compose-plugin` |
| Make | Any | `sudo apt install make` |
| Git | Any | `sudo apt install git` |

Verify installations:
```bash
docker --version
docker compose version
make --version
```

#### Docker Permissions

Add your user to the docker group to avoid using `sudo`:
```bash
sudo usermod -aG docker $USER
# Log out and back in for changes to take effect
```

### Initial Setup Steps

#### 1. Clone the Repository

```bash
git clone <repository-url>
cd Inception
```

#### 2. Configure Domain Resolution

Add the domain to your `/etc/hosts` file:
```bash
echo "127.0.0.1    opopov.42.fr" | sudo tee -a /etc/hosts
```

Verify:
```bash
ping -c 1 opopov.42.fr
```

#### 3. Create Environment Configuration

```bash
cp srcs/.env.example srcs/.env
```

Edit `srcs/.env` with your values:
```bash
# Domain
DOMAIN_NAME=opopov.42.fr

# MariaDB Configuration
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=<strong_password>
MYSQL_ROOT_PASSWORD=<strong_root_password>

# WordPress Admin (cannot contain 'admin' in username)
WP_TITLE=Inception
WP_ADMIN_USER=moderator
WP_ADMIN_PASSWORD=<admin_password>
WP_ADMIN_EMAIL=admin@opopov.42.fr

# WordPress Second User
WP_USER=guest
WP_USER_PASSWORD=<user_password>
WP_USER_EMAIL=editor@opopov.42.fr
```

#### 4. Create Data Directories

The Makefile handles this automatically, but you can create them manually:
```bash
mkdir -p /home/$USER/data/wordpress
mkdir -p /home/$USER/data/mariadb
```

> **Important**: Update the paths in `Makefile` and `docker-compose.yml` if your username differs from `opopov42`.

---

## Building and Launching the Project

### Using the Makefile

The Makefile provides convenient commands for managing the project:

| Command | Description |
|---------|-------------|
| `make` or `make build` | Build images and start containers |
| `make up` | Start containers without rebuilding |
| `make down` | Stop and remove containers |
| `make clean` | Stop containers and prune Docker system |
| `make fclean` | Full cleanup: remove volumes and data directories |
| `make re` | Full rebuild (fclean + build) |

### Makefile Details

```makefile
NAME = inception
DATA_DIR = /home/opopov42/data
WP_DIR = $(DATA_DIR)/wordpress
DB_DIR = $(DATA_DIR)/mariadb

build:
    @mkdir -p $(WP_DIR)           # Create WordPress data directory
    @mkdir -p $(DB_DIR)           # Create MariaDB data directory
    docker compose -f srcs/docker-compose.yml up -d --build
```

### Direct Docker Compose Commands

If you prefer not to use Make:

```bash
# Build and start
docker compose -f srcs/docker-compose.yml up -d --build

# Start without rebuild
docker compose -f srcs/docker-compose.yml up -d

# Stop
docker compose -f srcs/docker-compose.yml down

# View logs
docker compose -f srcs/docker-compose.yml logs -f

# Rebuild specific service
docker compose -f srcs/docker-compose.yml up -d --build nginx
```

---

## Managing Containers and Volumes

### Container Management

```bash
# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# Stop a specific container
docker stop nginx

# Start a specific container
docker start nginx

# Restart a container
docker restart nginx

# Execute command inside container
docker exec -it nginx bash
docker exec -it wp-php bash
docker exec -it mariadb bash

# View container resource usage
docker stats
```

### Volume Management

```bash
# List all volumes
docker volume ls

# Inspect volume details
docker volume inspect srcs_wordpress

# Remove unused volumes
docker volume prune

# Remove specific volume (data loss!)
docker volume rm <volume_name>
```

### Network Management

```bash
# List networks
docker network ls

# Inspect the inception network
docker network inspect srcs_inception

# See which containers are connected
docker network inspect srcs_inception --format '{{range .Containers}}{{.Name}} {{end}}'
```

### Cleanup Commands

```bash
# Remove stopped containers
docker container prune

# Remove unused images
docker image prune

# Remove all unused objects (containers, networks, images)
docker system prune

# Nuclear option: remove everything including volumes
docker system prune -a --volumes
```

---

## Data Storage and Persistence

### Data Locations

| Data Type | Container Path | Host Path |
|-----------|---------------|-----------|
| WordPress files | `/var/www/html` | `/home/opopov42/data/wordpress/` |
| MariaDB database | `/var/lib/mysql` | `/home/opopov42/data/mariadb/` |

### How Persistence Works

The `docker-compose.yml` defines bind mounts:

```yaml
services:
  nginx:
    volumes:
      - /home/opopov42/data/wordpress:/var/www/html
  
  wordpress:
    volumes:
      - /home/opopov42/data/wordpress:/var/www/html
  
  mariadb:
    volumes:
      - /home/opopov42/data/mariadb:/var/lib/mysql
```

- **Bind mounts** map host directories directly into containers
- Data persists even when containers are stopped/removed
- Both nginx and WordPress share the same volume (WordPress files)

### Inspecting Data

```bash
# View WordPress files
ls -la /home/opopov42/data/wordpress/

# View MariaDB data files
ls -la /home/opopov42/data/mariadb/

# Check disk usage
du -sh /home/opopov42/data/*
```

### Database Operations

```bash
# Connect to MariaDB
docker exec -it mariadb mysql -u root -p

# Inside MySQL shell:
SHOW DATABASES;
USE wordpress;
SHOW TABLES;
SELECT * FROM wp_users;

# Export database
docker exec mariadb mysqldump -u root -p<password> wordpress > backup.sql

# Import database
docker exec -i mariadb mysql -u root -p<password> wordpress < backup.sql
```

---

## Project Architecture

### Directory Structure

```
Inception/
├── Makefile                 # Build automation
├── README.md                # Main documentation
├── USER_DOC.md              # User documentation
├── DEV_DOC.md               # Developer documentation (this file)
└── srcs/
    ├── .env                 # Environment variables (gitignored)
    ├── .env.example         # Template for .env
    ├── docker-compose.yml   # Container orchestration
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile   # nginx image build
        │   └── default      # nginx site configuration
        ├── wordpress/
        │   ├── Dockerfile   # WordPress/PHP-FPM image build
        │   ├── script.sh    # WordPress installation script
        │   └── www.conf     # PHP-FPM pool configuration
        └── mariadb/
            ├── Dockerfile   # MariaDB image build
            ├── script.sh    # Database initialization script
            └── 50-server.cnf # MariaDB server configuration
```

### Container Build Process

#### nginx Dockerfile

```dockerfile
FROM debian:bookworm

RUN apt-get update && apt-get install -y nginx openssl

# Generate self-signed SSL certificate
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx.key \
    -out /etc/nginx/ssl/nginx.crt \
    -subj "/C=FR/ST=Paris/L=Paris/O=42/OU=42/CN=opopov.42.fr"

COPY default /etc/nginx/sites-available/.

# Run in foreground (required for Docker)
CMD ["nginx", "-g", "daemon off;"]
```

#### WordPress Dockerfile

```dockerfile
FROM debian:bookworm

RUN apt-get update && apt-get install -y php-fpm php-mysqli curl mariadb-client

COPY www.conf /etc/php/8.2/fpm/pool.d/.
COPY script.sh .

CMD ["./script.sh"]
```

#### MariaDB Dockerfile

```dockerfile
FROM debian:bookworm

RUN apt-get update && apt-get install -y mariadb-server

COPY 50-server.cnf /etc/mysql/mariadb.conf.d/.
COPY script.sh .

CMD ["./script.sh"]
```

### Service Communication

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Network: inception                │
│                                                             │
│  ┌──────────────┐      ┌──────────────┐      ┌───────────┐ │
│  │    nginx     │      │   wp-php     │      │  mariadb  │ │
│  │              │      │              │      │           │ │
│  │  Port 443 ◄──┼──────┤► Port 9000 ◄─┼──────┤► Port 3306│ │
│  │   (HTTPS)    │ FastCGI  (PHP-FPM)  │ MySQL │ (Database)│ │
│  │              │      │              │      │           │ │
│  └──────┬───────┘      └──────────────┘      └───────────┘ │
│         │                                                   │
└─────────┼───────────────────────────────────────────────────┘
          │
          ▼ Published to host
    0.0.0.0:443
```

### Key Configuration Files

#### nginx default (site configuration)

```nginx
server {
    listen 443 ssl;
    ssl_protocols TLSv1.2 TLSv1.3;
    
    root /var/www/html;
    index index.php;
    
    location ~ \.php$ {
        fastcgi_pass wp-php:9000;  # Forward PHP to WordPress container
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```

#### PHP-FPM www.conf

```ini
[www]
listen = 9000              # Listen on port 9000 (not Unix socket)
listen.allowed_clients = any
```

#### MariaDB 50-server.cnf

```ini
[mysqld]
bind-address = 0.0.0.0     # Accept connections from any container
```

---

## Development Workflow

### Making Changes to Containers

1. **Edit configuration files** in `srcs/requirements/<service>/`

2. **Rebuild the specific service**:
   ```bash
   docker compose -f srcs/docker-compose.yml up -d --build <service_name>
   ```

3. **Or rebuild everything**:
   ```bash
   make re
   ```

### Debugging

#### View logs
```bash
# All services
docker compose -f srcs/docker-compose.yml logs

# Specific service with follow
docker compose -f srcs/docker-compose.yml logs -f wordpress

# Last 100 lines
docker logs --tail 100 nginx
```

#### Interactive debugging
```bash
# Shell into container
docker exec -it nginx bash
docker exec -it wp-php bash
docker exec -it mariadb bash

# Check processes
docker exec nginx ps aux

# Test connectivity
docker exec wp-php ping mariadb
docker exec nginx ping wp-php
```

#### Test PHP-FPM connection
```bash
docker exec nginx curl -v http://wp-php:9000
```

### Common Development Tasks

#### Reset WordPress only (keep database)
```bash
rm -rf /home/opopov42/data/wordpress/*
docker compose -f srcs/docker-compose.yml up -d --build wordpress
```

#### Reset database only (keep WordPress files)
```bash
rm -rf /home/opopov42/data/mariadb/*
docker compose -f srcs/docker-compose.yml up -d --build mariadb
# Wait for DB to initialize, then rebuild WordPress
docker compose -f srcs/docker-compose.yml up -d --build wordpress
```

#### Change domain name
1. Update `DOMAIN_NAME` in `srcs/.env`
2. Update `server_name` in `srcs/requirements/nginx/default`
3. Update SSL certificate CN in nginx Dockerfile
4. Update `/etc/hosts` on host machine
5. Run `make re`

---

## Troubleshooting

### Container won't start

```bash
# Check logs for errors
docker logs <container_name>

# Check if port is already in use
sudo lsof -i :443

# Verify Docker daemon is running
systemctl status docker
```

### Database connection errors

```bash
# Verify MariaDB is running
docker exec mariadb mysqladmin ping -u root -p

# Check if database exists
docker exec -it mariadb mysql -u root -p -e "SHOW DATABASES;"

# Test connection from WordPress container
docker exec wp-php mysql -h mariadb -u wpuser -p
```

### PHP errors

```bash
# Check PHP-FPM logs
docker exec wp-php cat /var/log/php8.2-fpm.log

# Verify PHP-FPM is listening
docker exec wp-php netstat -tlnp | grep 9000
```

### Permission issues

```bash
# Fix WordPress file permissions
docker exec wp-php chown -R www-data:www-data /var/www/html
docker exec wp-php chmod -R 755 /var/www/html
```

---

## Environment Variables Reference

| Variable | Description | Used By |
|----------|-------------|---------|
| `DOMAIN_NAME` | Website domain | WordPress |
| `MYSQL_DATABASE` | Database name | MariaDB, WordPress |
| `MYSQL_USER` | Database user | MariaDB, WordPress |
| `MYSQL_PASSWORD` | Database user password | MariaDB, WordPress |
| `MYSQL_ROOT_PASSWORD` | Database root password | MariaDB |
| `WP_TITLE` | WordPress site title | WordPress |
| `WP_ADMIN_USER` | WordPress admin username | WordPress |
| `WP_ADMIN_PASSWORD` | WordPress admin password | WordPress |
| `WP_ADMIN_EMAIL` | WordPress admin email | WordPress |
| `WP_USER` | WordPress second user | WordPress |
| `WP_USER_PASSWORD` | Second user password | WordPress |
| `WP_USER_EMAIL` | Second user email | WordPress |
