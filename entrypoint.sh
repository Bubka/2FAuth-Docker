#!/bin/bash

echo "Now in entrypoint.sh for 2FAuth"
echo "Running as '$(whoami)' in group '$(id -g -n)'."
echo "Current working dir is '$(pwd)'"

# https://github.com/docker-library/wordpress/blob/master/docker-entrypoint.sh
# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
    local var="$1"
    local fileVar="${var}_FILE"
    local def="${2:-}"
    if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
        echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
        exit 1
    fi
    local val="$def"
    if [ "${!var:-}" ]; then
        val="${!var}"
    elif [ "${!fileVar:-}" ]; then
        val="$(< "${!fileVar}")"
    fi
    export "$var"="$val"
    unset "$fileVar"
}

# envs that can be appended with _FILE
envs=(
    SITE_OWNER
    APP_KEY
    DB_CONNECTION
    DB_HOST
    DB_PORT
    DB_DATABASE
    DB_USERNAME
    DB_PASSWORD
    PGSQL_SSL_MODE
    PGSQL_SSL_ROOT_CERT
    PGSQL_SSL_CERT
    PGSQL_SSL_KEY
    PGSQL_SSL_CRL_FILE
    REDIS_HOST
    REDIS_PASSWORD
    REDIS_PORT
    MAIL_DRIVER
    MAIL_HOST
    MAIL_PORT
    MAIL_FROM
    MAIL_USERNAME
    MAIL_PASSWORD
    MAIL_ENCRYPTION
)

echo "Now parsing _FILE variables."
for e in "${envs[@]}"; do
  file_env "$e"
done
echo "done!"

# touch DB file
echo "Touch DB file (if SQLite)..."
if [[ $DB_CONNECTION == "sqlite" ]]; then
  touch $TWOFAUTH_PATH/storage/database/database.sqlite
  echo "Touched!"
fi

echo "Dump auto load..."
composer dump-autoload > /dev/null 2>&1
echo "Discover packages..."
php artisan package:discover > /dev/null 2>&1

echo "Current working dir is '$(pwd)'"

echo "Wait for the db container."
if [[ -z "$DB_PORT" ]]; then
  if [[ $DB_CONNECTION == "mysql" ]]; then
    DB_PORT=3306
  fi
fi
if [[ -n "$DB_PORT" ]]; then
  /usr/local/bin/wait-for-it.sh "${DB_HOST}:${DB_PORT}" -t 60 -- echo "DB container is up."
fi

echo "Wait another 15 seconds in case the DB container needs to boot."
sleep 15
echo "Done waiting for the DB container to boot."

# echo "check for 2fauth database"
# SQL1="CREATE DATABASE IF NOT EXISTS ${DB_DATABASE} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
# SQL2="CREATE USER '${DB_USERNAME}'@'%' IDENTIFIED BY '${DB_PASSWORD}';"
# SQL3="GRANT ALL PRIVILEGES ON ${DB_DATABASE}.* TO '${DB_USERNAME}'@'%';"
# SQL4="FLUSH PRIVILEGES;"

# mysql -h $DB_HOST -u root -p$DB_PASSWORD -e "${SQL1}${SQL2}${SQL3}${SQL4}"
# echo "2FAuth db is ready"

echo "Current working dir is '$(pwd)'"
echo "Run various artisan commands..."

echo "Running migration commands..."
php artisan migrate
php artisan passport:install
php artisan storage:link
php artisan cache:clear > /dev/null 2>&1
php artisan config:cache > /dev/null 2>&1

echo "Current working dir is '$(pwd)'"

# set docker var.
# export IS_DOCKER=true

if [ -z $APACHE_RUN_USER ]
then
      APACHE_RUN_USER='www-data'
fi

if [ -z $APACHE_RUN_GROUP ]
then
      APACHE_RUN_GROUP='www-data'
fi

chown -R $APACHE_RUN_USER:$APACHE_RUN_GROUP $TWOFAUTH_PATH/storage
chmod -R 775 $TWOFAUTH_PATH/storage

echo "Go!"
exec apache2-foreground