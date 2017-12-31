#!/usr/bin/env bash

if [ ! -f /usr/bin/switch_php.sh ]; then
        echo "
#!/bin/bash

# Set current php version
PHP_CURRENT=\$1

# If no version has been retrieved
if [ ! \$PHP_CURRENT ] ;then
	exit 1
fi

# Set the php version to activate
PHP_TO_ACTIVATE=\$2

# If no version is passed to the script
if [ ! \$PHP_TO_ACTIVATE ] ;then
	exit 1
fi

echo -e \"Disable php \"\$PHP_CURRENT
# Dismod current php version
sudo a2dismod php\$PHP_CURRENT 1> /dev/null 2>&1

echo -e \"Enabling php \"\$PHP_TO_ACTIVATE
# Then enmod the one passed to the script
sudo a2enmod php\$PHP_TO_ACTIVATE 1> /dev/null 2>&1

# Don't forget php-config and php cli
if [ -f /usr/bin/php\$PHP_TO_ACTIVATE ]; then
	sudo update-alternatives --set php /usr/bin/php\$PHP_TO_ACTIVATE 1> /dev/null 2>&1
fi

if [ -f /usr/bin/php-config\$PHP_TO_ACTIVATE ]; then
	sudo update-alternatives --set php-config /usr/bin/php-config\$PHP_TO_ACTIVATE 1> /dev/null 2>&1
fi

# Last thing, restart apache
sudo service apache2 restart 1> /dev/null 2>&1
        " >> /usr/bin/switch_php.sh

    chmod 755 /usr/bin/switch_php.sh
    ln -s /usr/bin/switch_php.sh /usr/bin/switch_php
fi