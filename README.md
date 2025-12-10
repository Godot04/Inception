*This project has been created as part of the 42 curriculum by opopov.*

# Inception

A Docker-based infrastructure project that deploys a complete WordPress website with nginx and MariaDB, all running in separate containers on a custom Docker network.

---

## Description

**Inception** is a system administration project that introduces containerization using Docker and Docker Compose. The goal is to create a small infrastructure composed of different services running in isolated containers, following best practices for security and scalability.

The project deploys:
- **nginx** — Web server handling HTTPS traffic (TLSv1.2/TLSv1.3 only)
- **WordPress + PHP-FPM** — Content management system with FastCGI process manager
- **MariaDB** — Relational database storing WordPress data

All services run on Debian Bookworm (penultimate stable version) and communicate over a dedicated Docker network.

---

## Instructions

### Prerequisites

- Docker and Docker Compose installed
- Root/sudo access (for creating data directories)
- Entry in `/etc/hosts` mapping your domain to `127.0.0.1`:
  ```
  127.0.0.1    opopov.42.fr
  ```

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

- **Website**: https://opopov.42.fr (or your configured domain)
- **WordPress Admin Panel**: https://opopov.42.fr/wp-admin

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

### Tutorials
- [Docker Get Started Guide](https://docs.docker.com/get-started/)
- [nginx Beginner's Guide](https://nginx.org/en/docs/beginners_guide.html)
- [PHP-FPM Configuration](https://www.php.net/manual/en/install.fpm.configuration.php)

### AI Usage

AI assistants (GitHub Copilot) were used during development for:
- **Code explanations**: Understanding Docker concepts, Dockerfile syntax, and nginx configuration
- **Debugging**: Troubleshooting container communication and PHP-FPM configuration
- **Documentation**: Assisting in writing clear and comprehensive documentation
- **Best practices**: Guidance on security considerations and Docker design patterns

All AI-generated suggestions were reviewed, tested, and adapted to fit the specific project requirements.

---

## Project Description

### Overview

This project uses **Docker** to create isolated, reproducible containers for each service. Docker Compose orchestrates the multi-container application, defining:
- Service configurations and dependencies
- Network topology
- Volume mounts for data persistence
- Environment variable injection

### Architecture

```
                    ┌─────────────────────────────────────────────┐
                    │              Docker Network                 │
                    │                (inception)                  │
                    │                                             │
  Port 443          │   ┌─────────┐  Port 9000  ┌──────────────┐ │
WWW ◄───────────────┼───┤  nginx  ├─────────────┤  WordPress   │ │
    HTTPS (TLS)     │   │   SSL   │   FastCGI   │   PHP-FPM    │ │
                    │   └─────────┘             └──────┬───────┘ │
                    │         │                        │         │
                    │         │                        │ Port    │
                    │         │ Volume:                │ 3306    │
                    │         │ /var/www/html          │         │
                    │         │                        ▼         │
                    │         │                 ┌──────────────┐ │
                    │         └─────────────────┤   MariaDB    │ │
                    │                           │   Database   │ │
                    │                           └──────────────┘ │
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

1. **Base Image**: `debian:bookworm` — Uses the penultimate stable Debian release (not `:latest`) for reproducibility
2. **No PID 1 Issues**: All services run in foreground mode (`nginx -g "daemon off;"`, `php-fpm8.2 -F`, `mysqld`)
3. **Custom Network**: All containers communicate via the `inception` bridge network
4. **TLS Only**: nginx accepts only TLSv1.2 and TLSv1.3 connections
5. **Automated Setup**: WP-CLI handles WordPress installation without manual intervention

---

## Comparisons

### Virtual Machines vs Docker

| Aspect | Virtual Machines | Docker Containers |
|--------|-----------------|-------------------|
| **Isolation** | Full OS isolation with hypervisor | Process-level isolation via namespaces/cgroups |
| **Size** | Gigabytes (full OS + kernel) | Megabytes (shares host kernel) |
| **Startup Time** | Minutes | Seconds |
| **Resource Usage** | High (dedicated RAM/CPU per VM) | Low (shared kernel, no duplication) |
| **Portability** | Hardware-dependent | Runs anywhere Docker is installed |
| **Use Case** | Full OS environments, legacy apps | Microservices, CI/CD, development |

**Project Choice**: Docker provides lightweight, fast-starting containers perfect for deploying modular services like nginx, WordPress, and MariaDB.

---

### Secrets vs Environment Variables

| Aspect | Environment Variables | Docker Secrets |
|--------|----------------------|----------------|
| **Storage** | Plain text in .env files | Encrypted at rest |
| **Access** | Visible via `docker inspect` | Only inside container at `/run/secrets/` |
| **Scope** | Any environment | Docker Swarm mode only |
| **Security** | Less secure (visible in process list) | More secure (never stored in image layers) |
| **Complexity** | Simple | Requires Swarm setup |

**Project Choice**: Environment variables via `.env` file for simplicity in a single-host setup. The `.env` file is excluded from Git to prevent credential exposure.

---

### Docker Network vs Host Network

| Aspect | Docker Bridge Network | Host Network |
|--------|----------------------|--------------|
| **Isolation** | Containers isolated from host | Containers share host's network stack |
| **Port Mapping** | Requires explicit `-p` flag | Uses host ports directly |
| **Inter-container** | DNS resolution by container name | Must use `localhost` |
| **Security** | Better (containers separated) | Lower (no network isolation) |
| **Performance** | Slight overhead | Native performance |

**Project Choice**: Custom bridge network (`inception`) provides:
- Container name DNS resolution (e.g., `mariadb`, `wp-php`)
- Network isolation from host
- Controlled port exposure (only 443 published)

---

### Docker Volumes vs Bind Mounts

| Aspect | Docker Volumes | Bind Mounts |
|--------|---------------|-------------|
| **Management** | Managed by Docker | Manual path on host |
| **Location** | `/var/lib/docker/volumes/` | Any host path |
| **Portability** | Easy backup/restore | Host-dependent |
| **Performance** | Optimized for Docker | Direct filesystem access |
| **Use Case** | Database data, named storage | Development, config files |

**Project Choice**: **Bind mounts** to specific host paths (`/home/opopov42/data/`) for:
- Easy data inspection and backup
- Explicit control over storage location
- Requirement compliance (data stored at `/home/login/data/`)

---

## License

This project is part of the 42 School curriculum and is intended for educational purposes.
