*This project has been created as part of the 42 curriculum by opopov.*

# Inception

A Docker-based infrastructure project that deploys a complete WordPress website with nginx and MariaDB, all running in separate containers on a custom Docker network.

---

## Description

**Inception** is a system administration project that introduces containerization using Docker and Docker Compose. The goal is to create a small infrastructure composed of different services running in isolated containers.

The project deploys:
- **nginx** — Web server handling HTTPS traffic (TLSv1.2/TLSv1.3 only)
- **WordPress + PHP-FPM** — Content management system with FastCGI process manager
- **MariaDB** — Relational database storing WordPress data

All services run on Debian Bookworm and communicate over a dedicated Docker network.

---

## Instructions

### Prerequisites

- Docker and Docker Compose installed
- Root/sudo access (for creating data directories)
- Entry in `/etc/hosts` mapping your domain to `login.42.fr`:

### Configuration

1. Copy the environment template and fill in your values:
   ```bash
   cp srcs/.env.example srcs/.env
   ```

2. Edit `srcs/.env` with your credentials:
   ```bash
   # Domain
   DOMAIN_NAME=login.42.fr
   
   # MariaDB Configuration
   MYSQL_DATABASE=wordpress
   MYSQL_USER=wpuser
   MYSQL_PASSWORD=your_secure_password
   MYSQL_ROOT_PASSWORD=your_secure_root_password
   
   # WordPress Admin
   WP_TITLE=Inception
   WP_ADMIN_USER=moderator
   WP_ADMIN_PASSWORD=your_admin_password
   WP_ADMIN_EMAIL=admin@login.42.fr
   
   # WordPress Second User
   WP_USER=guest
   WP_USER_PASSWORD=your_user_password
   WP_USER_EMAIL=editor@login.42.fr
   ```

### Build and Run

```bash
# Build and start all containers
make

# Or use individual commands:
make build   # Build and start
make up      # Start (without rebuilding)
make down    # Stop containers
make clean   # Stop and prune Docker system
make fclean  # Full cleanup (removes volumes and data)
make re      # Rebuild from scratch
```

### Access

- **Website**: https://login.42.fr 
- **WordPress Admin Panel**: https://login.42.fr/wp-admin

---

## Resources

### Official Documentation
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [nginx Documentation](https://nginx.org/en/docs/)
- [WordPress Developer Resources](https://developer.wordpress.org/)
- [MariaDB Knowledge Base](https://mariadb.com/kb/)
- [WP-CLI Handbook](https://make.wordpress.org/cli/handbook/)
- [Debian Bookworm Release Notes](https://www.debian.org/releases/bookworm/)

### AI Usage

GitHub Copilot were used during development for:
- **Code explanations**: Understanding Docker concepts, Dockerfile syntax, and nginx configuration
- **Debugging**: Troubleshooting container communication and PHP-FPM configuration
- **Documentation**: Assisting in writing documentation

---

## Project Description

### Overview

This project uses **Docker** to run three services (nginx, WordPress, MariaDB) in separate containers. Docker allows each service to run independently while sharing the same host system resources efficiently.

**Why Docker?**
- **Isolation**: Each service runs in its own container without interfering with others
- **Lightweight**: Containers share the host kernel, using less resources than virtual machines
- **Portability**: The same setup works on any system with Docker installed
- **Easy management**: Docker Compose handles all services with simple commands

### Architecture

```
                    ┌─────────────────────────────────────────────┐
                    │              Docker Network                 │
                    │                (inception)                  │
                    │                                             │
  Port 443          │   ┌─────────┐  Port 9000  ┌──────────────┐  │
WWW ◄───────────────┼───┤  nginx  ├─────────────┤  WordPress   │  │
    HTTPS (TLS)     │   │   SSL   │   FastCGI   │   PHP-FPM    │  │
                    │   └─────────┘             └──────┬───────┘  │
                    │         │                        │          │
                    │         │                        │ Port     │
                    │         │ Volume:                │ 3306     │
                    │         │ /var/www/html          │          │
                    │         │                        ▼          │
                    │         │                 ┌──────────────┐  │
                    │         └─────────────────┤   MariaDB    │  │
                    │                           │   Database   │  │
                    │                           └──────────────┘  │
                    └─────────────────────────────────────────────┘
```

### Source Structure

```
Inception/
├── Makefile              # Build automation
├── README.md             # Project documentation
├── USER_DOC.md           # User documentation
├── DEV_DOC.md            # Developer documentation
└── srcs/
    ├── .env              # Environment variables (secrets)
    ├── .env.example      # Template for .env
    ├── docker-compose.yml
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   └── default       # nginx configuration
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── script.sh     # WordPress setup script
        │   └── www.conf      # PHP-FPM pool configuration
        └── mariadb/
            ├── Dockerfile
            ├── script.sh     # Database initialization
            └── 50-server.cnf # MariaDB configuration
```

### Design Choices

- **Base Image**: Debian Bookworm (penultimate stable version)
- **Foreground Mode**: All services run in foreground to work properly with Docker
- **Custom Network**: Containers communicate through a dedicated `inception` network
- **TLS Only**: nginx configured for HTTPS with TLSv1.2 and TLSv1.3
- **Automated Setup**: WP-CLI installs WordPress automatically without manual steps

---

## Technical Comparisons

### Virtual Machines vs Docker

**Virtual Machines:**
- Size: Gigabytes per VM (includes full operating system)
- Startup time: 1-2 minutes to boot
- Resources: Each VM needs dedicated RAM and CPU
- Use case: Running different operating systems 

**Docker:**
- Size: Megabytes per container (shares host kernel)
- Startup time: Less than 10 seconds
- Resources: All containers share host resources efficiently
- Use case: Running multiple services on the same OS

---

### Secrets vs Environment Variables

**Environment Variables:**
- Setup: Simple `.env` file with key-value pairs
- Security: Plain text (must keep `.env` out of Git)
- Complexity: Easy to use and understand

**Docker Secrets:**
- Setup: Requires Docker Swarm mode
- Security: Encrypted storage in Docker
- Complexity: More complex configuration

---

### Docker Network vs Host Network

**Docker Bridge Network:**
- Container communication: By name (e.g., `mariadb:3306`, `wp-php:9000`)
- Security: Containers isolated from host system
- Port control: Only expose specific ports

**Host Network:**
- Container communication: By `localhost` only
- Security: Containers have direct access to host network
- Port control: All container ports exposed to host

---

### Docker Volumes vs Bind Mounts

**Docker Volumes:**
- Location: Docker manages the location automatically
- Backup: Requires Docker commands to access
- Control: Docker decides where to store data

**Bind Mounts:**
- Location: You specify the exact path (`/home/login/data/`)
- Backup: Direct folder access on the host
- Control: You decide exactly where data is stored

---

