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

# Install projects tools
if [ "$PROJECT_TYPE" = "magento" ]
then
  curl -O https://files.magerun.net/n98-magerun.phar && chmod +x ./n98-magerun.phar && mv ./n98-magerun.phar /usr/local/bin/magerun
fi

if [ "$PROJECT_TYPE" = "magento2" ]
then
  curl -O https://files.magerun.net/n98-magerun2.phar && chmod +x ./n98-magerun2.phar && mv ./n98-magerun2.phar /usr/local/bin/magerun
  curl -LO https://s3.eu-west-2.amazonaws.com/magedbm2-releases/magedbm2.phar && chmod +x ./magedbm2.phar && mv ./magedbm2.phar /usr/local/bin/magedbm2
  curl -L https://github.com/punkstar/mageconfigsync/releases/download/0.5.0-beta.1/mageconfigsync-0.5.0-beta.1.phar > mageconfigsync.phar && chmod +x ./mageconfigsync.phar && mv ./mageconfigsync.phar /usr/local/bin/mageconfigsync
fi

if [ "$PROJECT_TYPE" = "wordpress" ]
then
  curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && chmod +x ./wp-cli.phar && mv wp-cli.phar /usr/local/bin/wpcli
fi

if [ "$PROJECT_TYPE" = "drupal7" ]
then
  COMPOSER_HOME=/opt/drush COMPOSER_BIN_DIR=/usr/local/bin composer global require drush/drush:7.x
fi

if [ "$PROJECT_TYPE" = "drupal8" ]
then
  COMPOSER_HOME=/opt/drush COMPOSER_BIN_DIR=/usr/local/bin composer global require drush/drush:8.x
fi

# Delete unused projects tools
if [ "$PROJECT_TYPE" != "magento2" ]
then
  rm /usr/local/bin/magento-installer
  rm /usr/local/bin/magento-command
fi

if [ "$PROJECT_TYPE" != "wordpress" ]
then
  rm /usr/local/bin/wp-installer
fi

# Configure composer
if [ "$PROJECT_TYPE" = "magento2" ]
then
  [ ! -z "${COMPOSER_MAGENTO_USERNAME}" ] && \
      composer config --global http-basic.repo.magento.com \
  $COMPOSER_MAGENTO_USERNAME $COMPOSER_MAGENTO_PASSWORD
fi

# Setup cron configuration
CRON_LOG=/var/log/cron.log
touch $CRON_LOG
echo "cron.* $CRON_LOG" > /etc/rsyslog.d/cron.conf
service rsyslog start

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- /usr/sbin/sshd "$@"
fi

exec "$@"