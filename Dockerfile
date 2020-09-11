FROM php:fpm
LABEL maintainer="Maxime Flasquin contact@mflasquin.fr"

# =========================================
# RUN update
# =========================================
RUN apt-get update

# =========================================
# Install dependencies
# =========================================
RUN apt-get install -y \
    libfreetype6-dev \
    openssh-server \
    imagemagick \
    graphicsmagick \
    curl \
    ca-certificates \
    gzip \
    zip \
    less \
    bzip2 \
    wget \
    libicu-dev \
    libjpeg62-turbo-dev \
    libzip-dev \
    libpng-dev \
    libxslt1-dev \
    sudo \
    cron \
    rsyslog \
    default-mysql-client \
    libmagickwand-dev \
    libmagickcore-dev \
    apt-transport-https \
    gnupg \
    libonig-dev

# =========================================
# Install tools
# =========================================
RUN apt-get install -y \
    vim \
    htop \
    openssl \
    git

# =========================================
# Install yarn
# =========================================    
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt-get install -y yarn

# =========================================
# Install npm
# =========================================
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get install -y nodejs

# =========================================
# Install npm tools
# =========================================
RUN npm install -g less
RUN npm install -g bower
RUN npm install -g gulp-cli

# =========================================
# Configure the GD library
# =========================================
RUN docker-php-ext-configure \
    gd

# =========================================
# Install php required extensions
# =========================================
RUN docker-php-ext-install \
  dom \
  gd \
  intl \
  mbstring \
  pdo_mysql \
  xsl \
  zip \
  soap \
  bcmath \
  mysqli \
  sockets \
  exif

# =========================================
# Install apcu
# =========================================
RUN pecl install -f apcu

# =========================================
# Install imagick
# =========================================
RUN pecl install -f imagick

# =========================================
# Install composer
# =========================================
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# =========================================
# Set ENV variables
# =========================================
ENV PHP_MEMORY_LIMIT 2G
ENV DEBUG false
ENV UPLOAD_MAX_FILESIZE 64M
ENV PROJECT_ROOT /var/www/htdocs

# =========================================
# Configure SSHD
# =========================================
RUN sed -ri 's,^PermitRootLogin\s+.*,PermitRootLogin no,' /etc/ssh/sshd_config \
	&& sed -ri 's,UsePAM yes,#UsePAM yes,g' /etc/ssh/sshd_config \
	&& sed -ri 's,#PasswordAuthentication yes,PasswordAuthentication no,g' /etc/ssh/sshd_config \
	&& sed -ri 's,^X11Forwarding\s+.*,X11Forwarding no,' /etc/ssh/sshd_config \
	&& sed -ri 's,^HostKey /etc/ssh/ssh_host_,HostKey /etc/ssh/keys/ssh_host_,' /etc/ssh/sshd_config \
	&& mkdir /var/run/sshd \
&& service ssh stop

# =========================================
# Create mflasquin user
# =========================================
RUN openssl rand -base64 32 > ./.pass \
	&& useradd -ms /bin/bash --password='$(cat ./.pass)' mflasquin \
	&& adduser mflasquin ssh \
	&& echo "$(cat ./.pass)\n$(cat ./.pass)\n" | passwd mflasquin \
	&& mv ./.pass /home/mflasquin/ \
	&& chown -Rf mflasquin:mflasquin /home/mflasquin

#Add custom bashrc
ADD ./bashrc.mflasquin /home/mflasquin/.bashrc

# =========================================
# Configure git
# =========================================
USER mflasquin
RUN git config --global user.email "contact@mflasquin.fr" \
	&& git config --global user.name "User mflasquin - Docker cli $(cat /etc/hostname)"

# =========================================
# SETUP SCRIPTS
# =========================================
USER root
ADD bin/* /usr/local/bin/
# MAGENTO2
RUN ["chmod", "+x", "/usr/local/bin/magento-installer"]
RUN ["chmod", "+x", "/usr/local/bin/magento-command"]
RUN ["chmod", "+x", "/usr/local/bin/wp-installer"]

# =========================================
# PHP Configuration
# =========================================
ADD etc/php-fpm.ini /usr/local/etc/php/conf.d/zz-custom.ini

# =========================================
# Set entrypoint
# =========================================
ADD docker-entrypoint.sh /docker-entrypoint.sh
RUN ["chmod", "+x", "/docker-entrypoint.sh"]
ENTRYPOINT ["/docker-entrypoint.sh"]

VOLUME /root/.composer/cache
VOLUME /home/mflasquin/.composer/cache

WORKDIR $PROJECT_ROOT

EXPOSE 22

# Launch run script
CMD ["-D"]