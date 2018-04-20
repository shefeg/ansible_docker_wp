FROM nginx:latest

COPY --chown=nginx:nginx config/. /etc/nginx/conf.d/
RUN mkdir /etc/nginx/ssl
COPY --chown=nginx:nginx certificates/. /etc/nginx/ssl/

VOLUME ["/etc/nginx/conf.d/", "/etc/nginx/ssl/"]

CMD ["nginx-debug", "-g", "daemon off;"]