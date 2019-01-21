#!bin/bash

dbUser="${DB_USER:-root}"
dbPass="${DB_PASS:-root}"
dbName="${DB_NAME:-db}"
env="${ENV:-release}"

#Creates the server config file with given environment variables
echo "ENV=${env}" >> /server.cnf
echo "DB_USER=${dbUser}" >> /server.cnf
echo "DB_PASS=${dbPass}" >> /server.cnf
echo "DB_NAME=${dbName}" >> /server.cnf

chown nginx /server.cnf
chmod 770 /server.cnf #Only the apache and root can access this file

echo ">>> Server has been started"

nginx
php-fpm
/usr/sbin/init
bin/bash
