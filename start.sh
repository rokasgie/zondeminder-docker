#!/bin/bash

# Load environment variables or set defaults
export MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-admin}
export DB_HOST=${DB_HOST:-mysql}
export DB_NAME=${DB_NAME:-zm}
export DB_USER=${DB_USER:-zmuser}
export DB_PASSWORD=${DB_PASSWORD:-zmpass}

# Wait for MySQL to be ready
echo "Waiting for MySQL to be ready..."
while ! mysqladmin ping -h"${DB_HOST}" -u"${DB_USER}" -p"${DB_PASSWORD}" --silent; do
    sleep 1
done
echo "MySQL is ready!"

# Import database schema
mysql -h"${DB_HOST}" -uroot -p"${MYSQL_ROOT_PASSWORD}" < /zm_create.sql

# Create MySQL user with mysql_native_password plugin
mysql -h"${DB_HOST}" -uroot -p"${MYSQL_ROOT_PASSWORD}" -e "
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED WITH mysql_native_password BY '${DB_PASSWORD}';
GRANT LOCK TABLES, ALTER, DROP, SELECT, INSERT, UPDATE, DELETE, CREATE, INDEX, ALTER ROUTINE, CREATE ROUTINE, TRIGGER, EXECUTE, REFERENCES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;"

echo "MySQL user and privileges configured!"

# Configure ZoneMinder database connection in zm.conf
if [ -f /etc/zm/zm.conf ]; then
    sed -i "s|^ZM_DB_HOST=.*|ZM_DB_HOST=${DB_HOST}|" /etc/zm/zm.conf
    sed -i "s|^ZM_DB_NAME=.*|ZM_DB_NAME=${DB_NAME}|" /etc/zm/zm.conf
    sed -i "s|^ZM_DB_USER=.*|ZM_DB_USER=${DB_USER}|" /etc/zm/zm.conf
    sed -i "s|^ZM_DB_PASS=.*|ZM_DB_PASS=${DB_PASSWORD}|" /etc/zm/zm.conf
fi

# Secure zm.conf
chown root:www-data /etc/zm/zm.conf && chmod 640 /etc/zm/zm.conf
# Create necessary ZoneMinder cache directories with proper permissions
echo "Creating /var/cache/zoneminder subdirectories and setting permissions"
mkdir -p /var/cache/zoneminder/{events,images,temp,cache}
chown -R www-data /var/cache/zoneminder
chmod -R 770 /var/cache/zoneminder


# Fix ownership and permissions on zm config and logs
echo "Setting ownership and permissions on /etc/zm and /var/log/zm"
chown -R root:www-data /etc/zm
chown -R www-data:www-data /var/log/zm
chmod -R 770 /etc/zm /var/log/zm

# Enable required Apache modules
a2enmod rewrite
a2enmod cgi
a2enmod headers
a2enmod expires

# Enable ZoneMinder Apache configuration
a2enconf zoneminder

# Start Apache and ZoneMinder services
service apache2 start
service zoneminder start

# Keep container running
tail -f /dev/null
