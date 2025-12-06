FROM debian:latest 

RUN apt-get update && apt-get upgrade -y && apt-get install -y php-fpm php-mysqli

CMD ["php-fpm8.4", "-F"]