# Developer Documentation

---

## Setting Up the Environment from Scratch

### Prerequisites

**Required software:**
- Docker 
- Docker Compose
- Make
- Git

**Install on Debian:**
```bash
sudo apt update
sudo apt install docker.io make git
```

**Add Docker permissions:**
```bash
sudo usermod -aG docker $USER
# Log out and back in
```

**Verify installation:**
```bash
docker --version
docker compose version
make --version
```

### Configuration Files

**1. Set up domain (add to `/etc/hosts`):**
```bash
echo "127.0.0.1    login.42.fr" | sudo tee -a /etc/hosts
```

**2. Create environment file:**
```bash
cp srcs/.env.example srcs/.env
```

**3. Edit `srcs/.env` with your credentials:**
```bash
DOMAIN_NAME=login.42.fr

MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=<your_password>
MYSQL_ROOT_PASSWORD=<your_root_password>

WP_ADMIN_USER=moderator
WP_ADMIN_PASSWORD=<your_admin_password>
WP_ADMIN_EMAIL=admin@login.42.fr

WP_USER=guest
WP_USER_PASSWORD=<your_user_password>
WP_USER_EMAIL=editor@login.42.fr
```

**Important:** The Makefile creates data directories automatically. If your username isn't `opopov42`, update paths in `Makefile` and `docker-compose.yml`.

---

## Building and Launching the Project

### Using the Makefile

```bash
make build    # Build and start everything
make up       # Start containers (no rebuild)
make down     # Stop containers
make clean    # Stop and prune Docker
make fclean   # Full cleanup (removes data!)
make re       # Rebuild from scratch
```

**What `make` does:**
1. Creates data directories (`/home/host/data/wordpress/` and `/home/host/data/mariadb/`)
2. Builds Docker images from Dockerfiles
3. Starts all containers in background

### Using Docker Compose Directly

If you prefer Docker Compose commands:

```bash
# Build and start
docker compose -f srcs/docker-compose.yml up -d --build

# Start without rebuilding
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

### Container Commands

```bash
# List running containers
docker ps

# List all containers
docker ps -a

# Start/stop/restart specific container
docker start nginx
docker stop nginx
docker restart nginx

# Access container shell
docker exec -it nginx bash
docker exec -it wp-php bash
docker exec -it mariadb bash

# View container logs
docker logs nginx
docker logs -f wp-php          # Follow logs in real-time
docker logs --tail 50 mariadb  # Last 50 lines

# View resource usage
docker stats
```

### Volume Commands

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect srcs_wordpress

# Remove unused volumes
docker volume prune

# Remove specific volume 
docker volume rm <volume_name>
```

### Network Commands

```bash
# List networks
docker network ls

# Inspect network
docker network inspect srcs_inception

```

### Cleanup Commands

```bash
# Remove stopped containers
docker container prune

# Remove unused images
docker image prune

# Remove all unused Docker objects
docker system prune

# Remove everything including volumes
docker system prune -a --volumes
```
---

## Data Storage and Persistence

### Where Data is Stored

**On the host machine:**
- WordPress files: `/home/host/data/wordpress/`
- MariaDB database: `/home/host/data/mariadb/`

**Inside containers:**
- WordPress files: `/var/www/html`
- MariaDB database: `/var/lib/mysql`

### How Persistence Works

**Bind mounts** connect host directories to container directories:

```yaml
services:
  nginx:
    volumes:
      - /home/host/data/wordpress:/var/www/html
  
  wordpress:
    volumes:
      - /home/host/data/wordpress:/var/www/html
  
  mariadb:
    volumes:
      - /home/host/data/mariadb:/var/lib/mysql
```

### Inspecting Data

```bash
# View WordPress files on host
ls -la /home/host/data/wordpress/

# View database files on host
ls -la /home/host/data/mariadb/

# Check disk usage
du -sh /home/host/data/*
```

### Database Operations

```bash
# Connect to database
docker exec -it mariadb mysql -u root -p

# Inside MySQL prompt:
SHOW DATABASES;
USE wordpress;
SHOW TABLES;
SELECT * FROM wp_users;

---

## Quick Reference

### Essential Commands

```bash
# Start project
make build

# Stop project
make down

# Full reset
make fclean && make

# View logs
docker logs nginx
docker logs wp-php
docker logs mariadb

# Access container shell
docker exec -it nginx bash
docker exec -it wp-php bash
docker exec -it mariadb bash

# Check running containers
docker ps

# View database
docker exec -it mariadb mysql -u root -p
```

### Project Structure

```
Inception/
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
└── srcs/
    ├── .env                    # Your credentials
    ├── .env.example            # Template
    ├── docker-compose.yml      # Service orchestration
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   └── default         # nginx config
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── script.sh       # WordPress setup
        │   └── www.conf        # PHP-FPM config
        └── mariadb/
            ├── Dockerfile
            ├── script.sh       # Database init
            └── 50-server.cnf   # MariaDB config
```

### Data Locations

- WordPress files: `/home/host/data/wordpress/`
- Database files: `/home/host/data/mariadb/`