FROM wordpress:4.9.5-fpm

RUN apt update && apt install -y curl less && \
  curl https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /tmp/wp-cli.phar && \
  chmod +x /tmp/wp-cli.phar && \
  mv /tmp/wp-cli.phar /usr/local/bin/wp && \
  wp --allow-root help

