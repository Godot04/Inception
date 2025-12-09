FROM debian:latest 

RUN apt-get update && apt-get upgrade -y && apt-get install -y php-fpm php-mysqli curl mariadb-client

COPY www.conf /etc/php/8.4/fpm/pool.d/.

COPY script.sh .

RUN chmod +x script.sh

CMD ["./script.sh"]