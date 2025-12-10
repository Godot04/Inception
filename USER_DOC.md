# User Documentation

This document explains how to use the Inception WordPress infrastructure as an end user or administrator.

---

## Services Overview

The Inception stack provides a complete WordPress website with three interconnected services:

| Service | Description | Container Name |
|---------|-------------|----------------|
| **nginx** | Web server handling all HTTPS traffic. Serves static files and forwards PHP requests to WordPress. | `nginx` |
| **WordPress + PHP-FPM** | Content management system for creating and managing website content. PHP-FPM processes PHP code. | `wp-php` |
| **MariaDB** | Database server storing all WordPress data (posts, users, settings, etc.). | `mariadb` |

### How They Work Together

1. You access the website via `https://opopov.42.fr` (port 443)
2. **nginx** receives your request and handles SSL/TLS encryption
3. For PHP pages, nginx forwards the request to **WordPress/PHP-FPM** (port 9000)
4. WordPress queries **MariaDB** (port 3306) for content
5. The response travels back through the same path to your browser

---

## Starting and Stopping the Project

### Starting the Services

Open a terminal in the project root directory and run:

```bash
make
```

This will:
- Create necessary data directories
- Build all Docker images
- Start all containers in the background

**First-time startup** may take a few minutes as Docker downloads base images and installs packages.

### Stopping the Services

```bash
make down
```

This stops all containers but **preserves your data** (database, WordPress files).

### Restarting Services

```bash
# Stop then start
make down
make up

# Or rebuild everything
make re
```

### Checking if Services Are Running

```bash
docker ps
```

You should see three containers running:
- `nginx` (port 443 exposed)
- `wp-php`
- `mariadb`

Example output:
```
CONTAINER ID   IMAGE                    STATUS          PORTS
abc123         srcs-nginx               Up 2 hours      0.0.0.0:443->443/tcp
def456         srcs-wordpress           Up 2 hours      9000/tcp
ghi789         srcs-mariadb             Up 2 hours      3306/tcp
```

---

## Accessing the Website

### Main Website

Open your browser and navigate to:

```
https://opopov.42.fr
```

> **Note**: You will see a browser security warning because the SSL certificate is self-signed. Click "Advanced" → "Proceed" to continue.

### WordPress Administration Panel

Access the admin dashboard at:

```
https://opopov.42.fr/wp-admin
```

Log in with your administrator credentials (configured in the `.env` file).

### Default User Accounts

| Role | Username | Purpose |
|------|----------|---------|
| Administrator | `moderator` | Full site management, plugins, themes, users |
| Author | `guest` | Can write and publish posts |

> **Important**: Passwords are set in the `srcs/.env` file. See the Credentials section below.

---

## Locating and Managing Credentials

### Where Credentials Are Stored

All credentials are stored in the environment file:

```
srcs/.env
```

### Credential Categories

#### Database Credentials
```bash
MYSQL_DATABASE=wordpress      # Database name
MYSQL_USER=wpuser             # Database user
MYSQL_PASSWORD=xxx            # Database user password
MYSQL_ROOT_PASSWORD=xxx       # Database root password
```

#### WordPress Admin (Administrator)
```bash
WP_ADMIN_USER=moderator       # Admin username
WP_ADMIN_PASSWORD=xxx         # Admin password
WP_ADMIN_EMAIL=xxx@xxx.fr     # Admin email
```

#### WordPress Second User (Author)
```bash
WP_USER=guest                 # Second user username
WP_USER_PASSWORD=xxx          # Second user password
WP_USER_EMAIL=xxx@xxx.fr      # Second user email
```

### Changing Passwords

#### Method 1: Via WordPress Admin Panel (Recommended for WordPress users)

1. Log in to `https://opopov.42.fr/wp-admin`
2. Go to **Users** → **All Users**
3. Click on the user you want to modify
4. Scroll to **Account Management** → **Set New Password**
5. Click **Update User**

#### Method 2: Via Environment File (Requires rebuild)

1. Edit `srcs/.env` with new passwords
2. Rebuild the project:
   ```bash
   make fclean
   make
   ```

> **Warning**: Method 2 will reset the WordPress installation. Use Method 1 to change passwords without data loss.

### Security Recommendations

- Use strong, unique passwords (at least 12 characters, mixed case, numbers, symbols)
- Never commit the `.env` file to version control
- Change default passwords before deploying to production
- Regularly backup your data

---

## Checking Service Health

### Quick Health Check

```bash
# Check running containers
docker ps

# Check container logs for errors
docker logs nginx
docker logs wp-php
docker logs mariadb
```

### Testing Each Service

#### 1. Test nginx (HTTPS)

```bash
curl -k https://opopov.42.fr
```

Expected: HTML content from WordPress (or `curl` output showing the page)

#### 2. Test WordPress/PHP

Visit `https://opopov.42.fr` in your browser. If you see the WordPress site, PHP-FPM is working.

#### 3. Test MariaDB Connection

```bash
docker exec -it mariadb mysql -u wpuser -p
```

Enter the password from `.env` (`MYSQL_PASSWORD`). If you get a MySQL prompt, the database is accessible.

### Common Issues and Solutions

| Problem | Possible Cause | Solution |
|---------|---------------|----------|
| "This site can't be reached" | Containers not running | Run `make` to start containers |
| "Connection refused" | nginx not listening | Check `docker logs nginx` for errors |
| Browser security warning | Self-signed certificate | Click "Advanced" → "Proceed" (normal behavior) |
| "Error establishing database connection" | MariaDB not ready | Wait 30 seconds and refresh; check `docker logs mariadb` |
| Cannot log in to WordPress | Wrong credentials | Verify username/password in `srcs/.env` |
| Site loads but looks broken | CSS/JS not loading | Clear browser cache, check nginx logs |

### Viewing Container Logs

```bash
# View all logs
docker logs nginx
docker logs wp-php
docker logs mariadb

# Follow logs in real-time
docker logs -f nginx

# View last 50 lines
docker logs --tail 50 nginx
```

---

## Data Locations

Your persistent data is stored on the host machine at:

| Data | Location |
|------|----------|
| WordPress files | `/home/opopov42/data/wordpress/` |
| MariaDB database | `/home/opopov42/data/mariadb/` |

### Backing Up Data

```bash
# Backup WordPress files
cp -r /home/opopov42/data/wordpress /path/to/backup/wordpress_backup

# Backup database
docker exec mariadb mysqldump -u root -p wordpress > backup.sql
```

### Restoring Data

```bash
# Restore WordPress files
cp -r /path/to/backup/wordpress_backup/* /home/opopov42/data/wordpress/

# Restore database
docker exec -i mariadb mysql -u root -p wordpress < backup.sql
```

---

## Frequently Asked Questions

**Q: Why do I see a security warning in my browser?**  
A: The SSL certificate is self-signed (created during container build). This is expected for development. In production, you would use a certificate from a trusted authority (e.g., Let's Encrypt).

**Q: Can I access the site from another computer on my network?**  
A: By default, the domain `opopov.42.fr` points to `127.0.0.1` (localhost). To access from other devices, you would need to configure the domain to point to your machine's IP address and ensure port 443 is accessible.

**Q: How do I completely reset everything?**  
A: Run `make fclean` to remove all containers, volumes, and data. Then run `make` to rebuild from scratch.

**Q: Where can I install WordPress plugins and themes?**  
A: Log in to the admin panel (`/wp-admin`), then navigate to **Plugins** or **Appearance** → **Themes**.
