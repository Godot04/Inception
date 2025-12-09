FROM debian:latest

RUN apt-get update && apt-get upgrade -y && apt-get install -y nginx openssl

RUN mkdir -p /etc/nginx/ssl

RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx.key \
    -out /etc/nginx/ssl/nginx.crt \
    -subj "/C=FR/ST=Paris/L=Paris/O=42/OU=42/CN=opopov.42.fr"

COPY default /etc/nginx/sites-available/.

CMD ["nginx", "-g", "daemon off;"]