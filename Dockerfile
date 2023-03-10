# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-alpine-nginx:3.17

# set version label
ARG BUILD_DATE
ARG VERSION
ARG BOOKSTACK_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="homerr"

# package versions
ARG BOOKSTACK_RELEASE

RUN \
  echo "**** install build packages ****" && \
  apk add --no-cache --virtual=build-dependencies \
    composer && \
  echo "**** install runtime packages ****" && \
  apk add --no-cache \
    fontconfig \
    memcached \
    php81-ctype \
    php81-curl \
    php81-dom \
    php81-gd \
    php81-iconv \
    php81-ldap \
    php81-mysqlnd \
    php81-pdo_mysql \
    php81-pecl-memcached \
    php81-phar \
    php81-tokenizer \
    qt5-qtbase \
    ttf-freefont && \
  echo "**** configure php-fpm to pass env vars ****" && \
  sed -E -i 's/^;?clear_env ?=.*$/clear_env = no/g' /etc/php81/php-fpm.d/www.conf && \
  grep -qxF 'clear_env = no' /etc/php81/php-fpm.d/www.conf || echo 'clear_env = no' >> /etc/php81/php-fpm.d/www.conf && \
  echo "env[PATH] = /usr/local/bin:/usr/bin:/bin" >> /etc/php81/php-fpm.conf && \
  echo "**** fetch bookstack ****" && \
  mkdir -p\
    /app/www && \
  if [ -z ${BOOKSTACK_RELEASE+x} ]; then \
    BOOKSTACK_RELEASE=$(curl -sX GET "https://api.github.com/repos/alex-j-butler/bookstack/releases/latest" \
    | awk '/tag_name/{print $4;exit}' FS='[""]'); \
  fi && \
  curl -o \
    /tmp/bookstack.tar.gz -L \
    "https://github.com/alex-j-butler/BookStack/archive/${BOOKSTACK_RELEASE}.tar.gz" && \
  tar xf \
    /tmp/bookstack.tar.gz -C \
    /app/www/ --strip-components=1 && \
  echo "**** install composer dependencies ****" && \
  composer install -d /app/www/ && \
  echo "**** cleanup ****" && \
  apk del --purge \
    build-dependencies && \
  rm -rf \
    /root/.composer \
    /tmp/*

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 80 443
VOLUME /config
