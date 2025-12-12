# User Documentation

---

## What Services Are Provided

This project runs a WordPress website with three services:

**nginx** - Web server that handles HTTPS connections on port 443

**WordPress + PHP-FPM** - The WordPress application for managing your website content

**MariaDB** - Database that stores all WordPress data (posts, users, settings)

**How they communicate:**
- You visit the site → nginx receives the request
- nginx forwards PHP requests → WordPress processes them
- WordPress requests MariaDB for data
- Response goes back through the chain to your browser

---

## Starting and Stopping the Project

### Start Everything

```bash
cd ~/Documents/Inception
make build
```

This builds and starts all containers. First run takes a few minutes.

### Stop Everything

```bash
make down
```

Data of WordPress files and database is preserved.

### Rebuild from Scratch

```bash
make fclean  # Remove everything including data
make build   # Start fresh
```

---

## Accessing the Website

### Main Website

Open your browser and go to:

```
https://login.42.fr
```

**Note:** You'll see a security warning because the certificate is self-signed. Click "Advanced" → "Proceed to login.42.fr" to continue.

### WordPress Admin Panel

Go to:

```
https://login.42.fr/wp-admin
```

Log in with the credentials from your `.env` file (see next section).

---

## Managing Credentials

### Where Credentials Are Stored

All usernames and passwords are in:

```
srcs/.env
```

### What's in the .env File

**Database credentials:**
```bash
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=your_password
MYSQL_ROOT_PASSWORD=your_root_password
```

**WordPress Admin user:**
```bash
WP_ADMIN_USER=moderator
WP_ADMIN_PASSWORD=your_admin_password
WP_ADMIN_EMAIL=admin@login.42.fr
```

**WordPress Second user:**
```bash
WP_USER=guest
WP_USER_PASSWORD=your_user_password
WP_USER_EMAIL=editor@login.42.fr
```

---

## Checking Services Are Running

### Quick Check

```bash
docker ps
```

You should see 3 containers running:
- `nginx`
- `wp-php`
- `mariadb`

### Check Container Logs

```bash
# View logs for any errors
docker logs nginx
docker logs wp-php
docker logs mariadb
```

### Test the Website

**Method 1:** Open `https://login.42.fr` in browser
- If the site loads → Everything works ✅

**Method 2:** Command line test
```bash
curl -k https://login.42.fr
```
- If you see HTML code → nginx and WordPress are working ✅

---

## Quick Reference

```bash
# Start project
make build

# Stop project
make down

# View running containers
docker ps

# Check logs
docker logs nginx
docker logs wp-php
docker logs mariadb

# Full reset
make fclean && make
```

**URLs:**
- Website: https://login.42.fr
- Admin: https://login.42.fr/wp-admin

**Data location:**
- WordPress files: `/home/host/data/wordpress/`
- Database: `/home/host/data/mariadb/`

---
