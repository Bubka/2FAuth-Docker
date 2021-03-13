# 0. Install debian buster-slim with php and apache2 (official php image)
FROM php:7.4-apache

# 1. Install development packages and clean up apt cache.
RUN apt-get update && apt-get install -y \
    curl \
    g++ \
    git \
    libbz2-dev \
    libfreetype6-dev \
    libicu-dev \
    libjpeg-dev \
    libmcrypt-dev \
    libpng-dev \
    libreadline-dev \
    libzip-dev \
    sudo \
    unzip \
    zip \
 && rm -rf /var/lib/apt/lists/*

# 2. Apache configs + document root.
RUN echo "ServerName 2fauth.local" >> /etc/apache2/apache2.conf

# ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
# RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
# RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

COPY vhost.conf /etc/apache2/sites-available/000-default.conf

# clean the git clone target directory
RUN rm -rvf /var/www/html/*;

# 3. mod_rewrite for URL rewrite and mod_headers for .htaccess extra headers like Access-Control-Allow-Origin-
RUN a2enmod rewrite headers

# 4. Start with base PHP config, then add extensions.
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

RUN docker-php-ext-install \
    bcmath \
    bz2 \
    calendar \
    intl \
    opcache \
    pdo_mysql \
    zip \
    gd

# 5. Composer.
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
# Downgrade composer to 1.10 branch
RUN composer self-update --1

# 6. We need a user with the same UID/GID as the host user
# so when we execute CLI commands, all the host file's permissions and ownership remain intact.
# Otherwise commands from inside the container would create root-owned files and directories.
# ARG uid
# RUN useradd -G www-data,root -u $uid -d /home/devuser devuser
# RUN mkdir -p /home/devuser/.composer && \
#     chown -R devuser:devuser /home/devuser

# 7. Source files
WORKDIR /var/www/html

RUN git clone -q https://github.com/Bubka/2FAuth /var/www/html

ENV TWOFAUTH_PATH=/var/www/html

# RUN mv /var/www/html/.env.example /var/www/html/.env

# set sqlite database
#RUN mkdir -p /2fauth/database/ && touch /2fauth/database/database.sqlite
#RUN sed -i 's|path\/to\/your\/database.sqlite|\/var\/www\/html\/database\/database.sqlite|g' /var/www/html/.env

RUN composer install

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY wait-for-it.sh /usr/local/bin/wait-for-it.sh

RUN set -eux; \
    chmod uga+x /usr/local/bin/entrypoint.sh && \
    chmod uga+x /usr/local/bin/wait-for-it.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]