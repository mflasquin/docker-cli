#!/bin/bash

[ "$DEBUG" = "true" ] && set -x

# Ensure our project directory exists
mkdir -p $PROJECT_ROOT
chown -R mflasquin:mflasquin $PROJECT_ROOT
chown -R mflasquin:mflasquin /home/mflasquin

#CHANGE UID IF NECESSARY
if [ ! -z "$MFLASQUIN_UID" ]
then
  echo "change mflasquin uuid"
  usermod -u $MFLASQUIN_UID mflasquin
fi

# Substitute in php.ini values
[ ! -z "${PHP_MEMORY_LIMIT}" ] && sed -i "s/!PHP_MEMORY_LIMIT!/${PHP_MEMORY_LIMIT}/" /usr/local/etc/php/conf.d/zz-custom.ini

if [ "$PROJECT_TYPE" = "magento2" ]
then
  [ ! -z "${MAGENTO_RUN_MODE}" ] && echo "env[MAGE_MODE] = !MAGENTO_RUN_MODE!;" >> /usr/local/etc/php-fpm.conf && sed -i "s/!MAGENTO_RUN_MODE!/${MAGENTO_RUN_MODE}/" /usr/local/etc/php-fpm.conf
fi

if [ "$PHP_XDEBUG_ENABLED" = "true" ]
then
  docker-php-ext-enable xdebug
fi

if [ "$INI_MODE" = "production" ]
then
  rm /usr/local/etc/php/php.ini-development && mv /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini
fi

exec "$@"