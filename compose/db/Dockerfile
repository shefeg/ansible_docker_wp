FROM mysql:5.7

COPY dump/db_setup.sql /docker-entrypoint-initdb.d

VOLUME ["/var/lib/mysql"]