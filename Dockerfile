FROM php:7.2-fpm-alpine

ARG php_display_errors=On
ARG php_opcache_enabled=On

ARG PHP_XDEBUG_IDE_KEY
ENV PHP_XDEBUG_IDE_KEY=$PHP_XDEBUG_IDE_KEY
ARG PHP_XDEBUG_PORT
ENV PHP_XDEBUG_PORT=$PHP_XDEBUG_PORT
ARG PHP_XDEBUG_REMOTE_HOST
ENV PHP_XDEBUG_REMOTE_HOST=$PHP_XDEBUG_REMOTE_HOST
ARG PHP_XDEBUG_IDE_ENABLED
ENV PHP_XDEBUG_IDE_ENABLED=$PHP_XDEBUG_IDE_ENABLED

RUN set -xe \
 && apk update \
 && apk --no-cache add \
    bash \
    libpq \
    icu-dev \
    libzip-dev \
    postgresql-dev \
    make \
    git \
    openssh \
    nodejs \
    npm && \
    npm install -g bower \
    argon2-dev \
		coreutils \
		curl-dev \
		libedit-dev \
		libressl-dev \
		libsodium-dev \
		libxml2-dev \
		sqlite-dev \
        autoconf \
		dpkg-dev dpkg \
		file \
		g++ \
		gcc \
		libc-dev \
		make \
		pkgconf \
		re2c \
    ca-certificates \
		curl \
		tar \
		xz \
        libressl
# ensure www-data user exists
RUN set -x \
	&& addgroup -g 82 -S www-data \
	&& adduser -u 82 -D -S -G www-data www-data

RUN if [ $PHP_XDEBUG_IDE_ENABLED = 1 ] ; then \
	apk add --no-cache ${PHPIZE_DEPS} \
	    && pecl install xdebug-2.9.8 \
	    && docker-php-ext-enable xdebug \
	    && echo "xdebug.idekey=$PHP_XDEBUG_IDE_KEY" >> "${PHP_INI_DIR}/conf.d/docker-php-ext-xdebug.ini" \
	    && echo "xdebug.remote_port=$PHP_XDEBUG_PORT" >> "${PHP_INI_DIR}/conf.d/docker-php-ext-xdebug.ini" \
	    && echo "xdebug.remote_enable=1" >> "${PHP_INI_DIR}/conf.d/docker-php-ext-xdebug.ini" \
	    && echo "xdebug.remote_autostart=1" >> "${PHP_INI_DIR}/conf.d/docker-php-ext-xdebug.ini" \
	    && echo "xdebug.remote_connect_back=0" >> "${PHP_INI_DIR}/conf.d/docker-php-ext-xdebug.ini" \
	    && echo "xdebug.remote_host=$PHP_XDEBUG_REMOTE_HOST" >> "${PHP_INI_DIR}/conf.d/docker-php-ext-xdebug.ini"; \
fi

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

RUN chmod +x /usr/local/bin/install-php-extensions && sync && \
    install-php-extensions \
	intl \
	zip \
	http \
	memcache \
	memcached \
	pdo_mysql \
    pdo_pgsql

RUN docker-php-ext-enable opcache

#install COMPOSER
COPY --from=composer:1.10 /usr/bin/composer /usr/bin/composer
RUN composer --version
ENV COMPOSER_ALLOW_SUPERUSER 1

# fix timezone
ENV TIMEZONE America/Sao_Paulo
RUN ln -snf /usr/share/zoneinfo/$TIMEZONE /etc/localtime && echo $TIMEZONE > /etc/timezone

RUN echo "date.timezone=${TIMEZONE}" > "$PHP_INI_DIR/conf.d/00-docker-php-date-timezone.ini"

# COPY $PWD/docker/php/entrypoint.sh /
# RUN chmod +x /entrypoint.sh
# ENTRYPOINT ["/entrypoint.sh"]

# RUN mkdir /app \
# 	&& chown 1000:1000 /app \
# 	&& touch /tmp/xdebug.log \
# 	&& chown 1000:1000 /tmp/xdebug.log

WORKDIR /var/www/html

EXPOSE 9000
# WORKDIR /app
CMD ["php-fpm"]
