FROM debian:latest 

RUN apt-get update && apt-get upgrade -y && apt-get install -y php-fpm php-mysqli

COPY www.conf /etc/php/8.4/fpm/pool.d/.

CMD ["php-fpm8.4", "-F"]