#!/usr/bin/env bash

#
# Write Log in File
#
write_log ()
{
	echo "$1:$2" >> $LOG_FILE
	echo "$3" >> $LOG_FILE
}

#
# Export Variables
#
export DEBIAN_FRONTEND=noninteractive

#
# Variables
#
DBHOST=localhost
DBNAME=wp
DBUSER=root
DBPASSWD=root
REMOTE_HOST=192.168.33.10
LOG_FILE=/vagrant/vm_build.log
PHP_VERSION_LIST=(5.6 7.0 7.1 7.2)
PHP_DEFAULT_VERSION=7.1

#
# Apt Get Update
#
echo -e "\nUpdating packages list ...\n"
write_log "APTGET" "Update packages"

apt-get -qq update

#
# Setup Locales
#
echo -e "\nInstall Locales ..."
write_log "APTGET" "Install Locales ..."

apt-get install -y language-pack-en-base
apt-get install --reinstall locales

locale-gen --no-purge --lang en_US.UTF-8

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

echo "export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8" >> ~/.bash_profile

dpkg-reconfigure locales

#
# Add extra repositories
#
echo -e "\nAdd Repositories ..."
write_log "APTGET" "Install Repositories ..."

apt-add-repository -y ppa:ondrej/php
add-apt-repository -y ppa:git-core/ppa

apt-get update

#
# Install Bases
#
echo -e "\nInstall base packages ..."
write_log "APTGET" "Install base packages ..."

apt-get -y install mc vim curl build-essential python-software-properties rubygems ruby-dev 2>> $LOG_FILE

#
# MySQL setup for development purposes ONLY
#
echo -e "\nInstall MySQL specific packages and settings ..."
write_log "APTGET" "Install MYSQL ..."

debconf-set-selections <<< "mysql-server mysql-server/root_password password $DBPASSWD"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DBPASSWD"
debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password $DBPASSWD"
debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password $DBPASSWD"
debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password $DBPASSWD"
debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect none"
apt-get -y install mysql-server phpmyadmin 2>> $LOG_FILE

mysql -uroot -p$DBPASSWD -e "CREATE DATABASE $DBNAME" 2>> $LOG_FILE
mysql -uroot -p$DBPASSWD -e "grant all privileges on $DBNAME.* to '$DBUSER'@'%' identified by '$DBPASSWD'" 2>> $LOG_FILE

sed -i "s/bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/my.cnf

apt-get -y install php \
    apache2 \
    libapache2-mod-php \
    php-curl \
    php-gd \
    php-mysql \
    php-mongodb \
    php-xml \
    php-gettext 2>> $LOG_FILE

a2enmod rewrite 2>> $LOG_FILE

sed -i "s/AllowOverride None/AllowOverride All/g" /etc/apache2/apache2.conf

echo "ServerName localhost" >> /etc/apache2/apache2.conf

rm -rf /var/www/html
ln -fs /vagrant /var/www/html

#
# Install PHP
#
echo -e "\nInstall Php ..."
write_log "PHP" "Configure Stuffs" "Xdebug, phpini, PHPCS ..."

for PHP_VERSION in "${PHP_VERSION_LIST[@]}"; do
    if [  $(dpkg-query -W -f='${Status}' php${PHP_VERSION} 2>> /dev/null | grep -c "ok installed") -eq 0 ]; then
        write_log 'INSTALLING PHP ' ${PHP_VERSION}
    	apt-get -y install php${PHP_VERSION} 2>> $LOG_FILE

        apt-get -y install php${PHP_VERSION}-xml \
            php${PHP_VERSION}-bz2 \
            php${PHP_VERSION}-curl \
            php${PHP_VERSION}-gd \
            php${PHP_VERSION}-json \
            php${PHP_VERSION}-mbstring \
            php${PHP_VERSION}-mysql \
            php${PHP_VERSION}-mysqli \
            php${PHP_VERSION}-mysqlnd \
            php${PHP_VERSION}-zip \
            php${PHP_VERSION}-opcache \
            php${PHP_VERSION}-pdo \
            php${PHP_VERSION}-pdo-mysql \
            php${PHP_VERSION}-readline \
            php${PHP_VERSION}-dev \
            php${PHP_VERSION}-fpm 2>> $LOG_FILE
    fi

    if [ -f /etc/php/${PHP_VERSION}/apache2/php.ini ]; then
        sed -i -r "s/;?upload_max_filesize\s*=.*/upload_max_filesize = 100M/g" /etc/php/${PHP_VERSION}/apache2/php.ini
        sed -i -r "s/;?post_max_size\s*=.*/post_max_size = 100M/g" /etc/php/${PHP_VERSION}/apache2/php.ini
        sed -i -r "s/;?error_reporting\s*=\s.*/error_reporting = E_ALL/" /etc/php/${PHP_VERSION}/apache2/php.ini
        sed -i -r "s/;?display_errors\s*=\s.*/display_errors = On/" /etc/php/${PHP_VERSION}/apache2/php.ini
        sed -i -r "s/;?log_errors\s*=.*/log_errors = On/" /etc/php/${PHP_VERSION}/apache2/php.ini
        sed -i -r "s/;?error_log\s*=.*/error_log = \/var\/log\/php\/error.log/" /etc/php/${PHP_VERSION}/apache2/php.ini

        if ! grep -Fxq '[XDebug]' /etc/php/${PHP_VERSION}/apache2/php.ini; then
        echo '
[XDebug]
zend_extension="xdebug.so"
xdebug.remote_enable=1
xdebug.remote_connect_back=1
xdebug.profiler_enable=0
xdebug.profiler_enable_trigger=1
xdebug.profiler_output_dir="~/xdebug/profiler"
xdebug.idekey=XDEBUG_ECLIPSE
xdebug.remote_port=9000
xdebug.remote_host='${REMOTE_HOST}'
xdebug.remote_autostart=0
xdebug.remote_log=/vagrant/xdebug.log
xdebug.max_nesting_level=100
        ' >> /etc/php/${PHP_VERSION}/apache2/php.ini
        fi
    fi
done

apt-get install php-xdebug 2>> $LOG_FILE

a2dismod php7.2
a2enmod php$PHP_DEFAULT_VERSION
update-alternatives --set php /usr/bin/php$PHP_DEFAULT_VERSION 2>> $LOG_FILE

pear channel-update pear.php.net 2>> $LOG_FILE
pear install PHP_CodeSniffer

#
# Node
#
echo -e "\nInstall Node"
write_log "APTGET" "Install Node ..."

curl -sL https://deb.nodesource.com/setup_8.x -o nodesource_setup.sh

if [ -f nodesource_setup.sh ]; then
    sh nodesource_setup.sh 2>> $LOG_FILE
    apt-get -y install nodejs 2>> $LOG_FILE
fi

#
# Git
#
echo -e "\nInstall Git ..."
write_log "APTGET" "Install Git ..."

if [  $(dpkg-query -W -f='${Status}' git 2>> /dev/null | grep -c "ok installed") -eq 0 ]; then
	apt-get -y install git 2>> $LOG_FILE
else
	apt-get -y install --only-upgrade git 2>> $LOG_FILE
fi

#
# Composer
#
echo -e "\nInstall Composer ..."
write_log "COMPOSER" "Install ..."

if [ ! -f /usr/bin/composer ]; then

    if [  $(dpkg-query -W -f='${Status}' composer 2>> /dev/null | grep -c "ok installed") -eq 0 ]; then
    	EXPECTED_SIGNATURE=$(wget -q -O - https://composer.github.io/installer.sig)
    	php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" 2>> $LOG_FILE
    	ACTUAL_SIGNATURE=$(php -r "echo hash_file('SHA384', 'composer-setup.php');")

    	if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]; then
            write_log 'Error' 'Invalid installer signature'
        	rm composer-setup.php
     	  	exit 1
    	fi
    fi

    php composer-setup.php --quiet 2>> $LOG_FILE
    rm composer-setup.php

    if [ ! composer.phar ]; then
        write_log "Composer Phar" "File Not found"
    else
        mv composer.phar /usr/bin/composer.phar
        ln -s /usr/bin/composer.phar /usr/bin/composer
        chmod 755 /usr/bin/composer.phar
    fi

fi

#
# Task Runners & Package Managers
#
echo -e "\nInstall Task Runners and Package Managers ..."
write_log "NPM" "Install Task Runners and Package Managers ..."

npm install -g bower 2>> $LOG_FILE
npm install -g grunt 2>> $LOG_FILE
npm install -g gulp 2>> $LOG_FILE

#
# Pre Processors
#
echo -e "\nInstall Css Preprocessors ..."
write_log "Css" "Install Preprocessors ..."

sudo gem install sass --no-user-install 2>> $LOG_FILE

#
# WordPress Stuffs
#
echo -e "\nInstall WP Stuffs ..."
write_log 'WP' 'Install CLI ...'

curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar 1> /dev/null 2>> $LOG_FILE

if [ -f wp-cli.phar ]; then
    php wp-cli.phar --info 2>> $LOG_FILE
    chmod +x wp-cli.phar 2>> $LOG_FILE
    sudo mv wp-cli.phar /usr/bin/wp 2>> $LOG_FILE
else
    write_log 'WPCLI' 'No way to locate the file wp-cli.phar'
fi

#
# Restart Services
#
echo -e "\nRestart Services ..."
write_log 'SERV' 'Restart Services ...'

service apache2 restart 2>> $LOG_FILE
