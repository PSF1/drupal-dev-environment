#!/bin/bash

# Configure script arguments and versions here
PHP_VERSION=7.0
DRUSH_VERSION=8.1.10
NODE_VERSION=6.10.0
DEVELOPER=developer
LOCALE=es_ES.UTF-8
MYSQL_PASS="toor"
SSH_PASS="toor"
AUTOYES=false

# Functions
wait_user () {
	if [ "$AUTOYES" != true ]; then
		echo "Press [ENTER] to continue"
		read
	fi
}

show_msg () {
    echo --------------------------------------------------------------------------------------
	echo -
	echo - $1
	echo -
	echo --------------------------------------------------------------------------------------
	wait_user
}

usage() {
	echo 
	echo "$0 Help: "
	echo "-h, --help This help"
	echo "-l, --locale System locale. Ex. es_ES.UTF-8"
	echo "-p, --php PHP Version. Ex. 7.0"
	echo "-y, --unattended Unattended execution."
	echo 
}

configuration() {
	echo 
	echo "Configuration: "
	printf "LOCALE = %s\n" "$LOCALE"
	printf "PHP_VERSION = %s\n" "$PHP_VERSION"
	printf "Unattended = %s\n" "$AUTOYES"
	echo 
}

while [ "$1" != "" ]; do
    case $1 in
        -l | --locale )         shift
                                LOCALE=$1
                                ;;
		-p | --php )         	shift
                                PHP_VERSION=$1
                                ;;
        -y | --unattended )    	AUTOYES=true
                                ;;
        -h | --help )           usage
								configuration
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

configuration
wait_user

#Check that user is root
if [ $USER != 'root' ]; then
  show_msg '"ERROR!" You must execute this script how root.';
  exit;
fi

show_msg "This script do a insecure system, DON'T RUN IT IN YOUR MAIN SYSTEM !! It's build to run in VMs like LXC, VirtualBox or Vagrant."

# Base Packages
show_msg "Base Packages: locales, git, wget, curl, vim, debconf-utils, sudo, build-essential, autoconf, libpcre3-dev, rsync, software-properties-common, python-software-properties, htop, nano"
apt-get update -y \
    && apt-get install -y \
       locales \
       git \
       wget \
       curl \
       vim \
       debconf-utils \
       sudo \
       build-essential \
       autoconf \
       libpcre3-dev \
       rsync \
       software-properties-common \
       python-software-properties \
       htop \
       nano

# Set locale
show_msg "Set locale: $LOCALE"
locale-gen $LOCALE && update-locale LANG=$LOCALE

# Setup Apache.
show_msg "Setup Apache HTTP/S, with ports 80, 443, 8080, 8081, 8443. Document root in: /var/www/. Mods: rewrite, ssl."
apt-get install -y apache2 apache2-utils libapache2-mod-geoip geoip-database \
    && sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf \
    && sed -i 's/DocumentRoot \/var\/www\/html/DocumentRoot \/var\/www/' /etc/apache2/sites-available/000-default.conf \
    && sed -i 's/DocumentRoot \/var\/www\/html/DocumentRoot \/var\/www/' /etc/apache2/sites-available/default-ssl.conf \
    && echo "Listen 8080" >> /etc/apache2/ports.conf \
    && echo "Listen 8081" >> /etc/apache2/ports.conf \
    && echo "Listen 8443" >> /etc/apache2/ports.conf \
    && sed -i 's/VirtualHost \*:80/VirtualHost \*:\*/' /etc/apache2/sites-available/000-default.conf \
    && sed -i 's/VirtualHost __default__:443/VirtualHost _default_:443 _default_:8443/' /etc/apache2/sites-available/default-ssl.conf \
    && chown -R www-data:www-data /var/www/ \
    && a2enmod rewrite \
    && a2enmod ssl \
    && a2ensite default-ssl.conf

# PHP and PHP packages that are important to running dynamic PHP based applications with Apache2 Webserver support 
show_msg "Setup PHP $PHP_VERSION from ondrej/php, mods: bcmath, cli, common, curl, dev, enchant, gd, gmp, imap, interbase, intl, json, ldap, mbstring, memcache, mysql, mcrypt, opcache, php-pear, pspell, readline, recode, soap, tidy, xdebug, xml, xmlrpc, zip"
add-apt-repository ppa:ondrej/php -y
sudo apt-get update -y
sudo apt-get install -y \
    php$PHP_VERSION \
    libapache2-mod-php$PHP_VERSION \
    php$PHP_VERSION-bcmath \
    php$PHP_VERSION-cli \
    php$PHP_VERSION-common \
    php$PHP_VERSION-curl \
    php$PHP_VERSION-dev \
    php$PHP_VERSION-enchant \
    php$PHP_VERSION-gd \
    php$PHP_VERSION-gmp \
    php$PHP_VERSION-imap \
    php$PHP_VERSION-interbase \
    php$PHP_VERSION-intl \
    php$PHP_VERSION-json \
    php$PHP_VERSION-ldap \
    php$PHP_VERSION-mbstring \
    php$PHP_VERSION-memcache \
    php$PHP_VERSION-mysql \
    php$PHP_VERSION-mcrypt \
    php$PHP_VERSION-opcache \
    php-pear \
    php$PHP_VERSION-pspell \
    php$PHP_VERSION-readline \
    php$PHP_VERSION-recode \
    php$PHP_VERSION-soap \
    php$PHP_VERSION-tidy \
    php$PHP_VERSION-xdebug \
    php$PHP_VERSION-xml \
    php$PHP_VERSION-xmlrpc \
    php$PHP_VERSION-zip

# Config PHP.
show_msg "Config PHP"
sudo wget https://raw.githubusercontent.com/PSF1/drupal-dev-environment/ubuntu.16.04/cfgs/php.ini
sudo cp php.ini /etc/php/$PHP_VERSION/apache2/php.ini
sudo mv php.ini /etc/php/$PHP_VERSION/cli/php.ini

# Setup XDebug.
show_msg "Setup XDebug"
sudo echo "xdebug.max_nesting_level = 300" >> /etc/php/$PHP_VERSION/apache2/conf.d/20-xdebug.ini \
    && sudo echo "xdebug.remote_enable=1" >> /etc/php/$PHP_VERSION/apache2/conf.d/20-xdebug.ini \
    && sudo echo "xdebug.remote_handler=dbgp" >> /etc/php/$PHP_VERSION/apache2/conf.d/20-xdebug.ini \
    && sudo echo "xdebug.remote_mode=req" >> /etc/php/$PHP_VERSION/apache2/conf.d/20-xdebug.ini \
    && sudo echo "xdebug.remote_connect_back=1" >> /etc/php/$PHP_VERSION/apache2/conf.d/20-xdebug.ini \
    && sudo echo "xdebug.remote_port=9000" >> /etc/php/$PHP_VERSION/apache2/conf.d/20-xdebug.ini

# Setup MySQL.
show_msg "Setup MySQL"
#	Ejemplo MySQL => http://www.thisprogrammingthing.com/2013/getting-started-with-vagrant/
debconf-set-selections <<< 'mysql-server mysql-server/root_password password $MYSQL_PASS'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password $MYSQL_PASS'
apt-get install -y mysql-server mysql-client
show_msg "Mysql user root and password $MYSQL_PASS."

# Setup SSH.
show_msg "Setup SSH"
apt-get install -y openssh-server \
    && echo 'root:$SSH_PASS' | chpasswd \
    && sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && mkdir /var/run/sshd && chmod 0755 /var/run/sshd \
    && mkdir -p /root/.ssh/ && touch /root/.ssh/authorized_keys \
    && sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
show_msg "SSH root user password: $SSH_PASS"

# Supervisor
show_msg "Supervisor"
apt-get install -y supervisor \
    && mkdir -p /var/log/supervisor \
    && echo '[program:apache2]\ncommand=/bin/bash -c "source /etc/apache2/envvars && exec /usr/sbin/apache2 -DFOREGROUND"\nautorestart=true\n\n' >> /etc/supervisor/supervisord.conf \
    && echo '[program:sshd]\ncommand=/usr/sbin/sshd -D\n\n' >> /etc/supervisor/supervisord.conf

# ------------------------------------------------------*
# DRUPAL support
# ------------------------------------------------------*

# ------------------------------------------
# Start USER developer 
# Create user 
show_msg "Create user developer"
addgroup $DEVELOPER
useradd $DEVELOPER -s /bin/bash -m -g $DEVELOPER
usermod --password $DEVELOPER $DEVELOPER
echo "$DEVELOPER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$DEVELOPER
chmod 0440 /etc/sudoers.d/$DEVELOPER

wget https://raw.githubusercontent.com/PSF1/drupal-dev-environment/ubuntu.16.04/cfgs/bashrc
mv bashrc /home/$DEVELOPER/.bashrc

wget https://raw.githubusercontent.com/PSF1/drupal-dev-environment/ubuntu.16.04/cfgs/bash_aliases
mv bash_aliases /home/$DEVELOPER/.bash_aliases

wget https://raw.githubusercontent.com/PSF1/drupal-dev-environment/ubuntu.16.04/cfgs/bash_profile
mv bash_profile /home/$DEVELOPER/.bash_profile
show_msg "Added user developer with password developer."

# Change user for install dependencies
show_msg "Install Drupal dependencies"
cd /home/$DEVELOPER
chown $DEVELOPER:$DEVELOPER /home/$DEVELOPER -R

mkdir /home/$DEVELOPER/Projects \
    && chown $DEVELOPER:$DEVELOPER /home/$DEVELOPER/Projects

# Install node
show_msg "Install nodejs"
cd /home/$DEVELOPER
su $DEVELOPER -c "curl -sL \"https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz\" -o node-linux-x64.tar.gz"
tar -zxf "node-linux-x64.tar.gz" -C /usr/local --strip-components=1
su $DEVELOPER -c "rm node-linux-x64.tar.gz "
ln -s /usr/local/bin/node /usr/local/bin/nodejs

# Install bower and gulp-cli globally
show_msg "Install bower and gulp-cli globally"
npm install --global bower gulp-cli

# Install Composer
show_msg "Install Composer"
sudo curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
sudo chmod a+x /usr/local/bin/composer

# Install Drush, drupal console, coder and codesniffer standards.
show_msg "Install hirak/prestissimo, Drush, drupal console, coder and codesniffer standards"
su $DEVELOPER -c "composer global require hirak/prestissimo"
su $DEVELOPER -c "composer global require drush/drush:$DRUSH_VERSION "
su $DEVELOPER -c "composer global update "
su $DEVELOPER -c "composer global require drupal/console:@stable "
su $DEVELOPER -c "composer global require drupal/coder "
su $DEVELOPER -c "composer global require dealerdirect/phpcodesniffer-composer-installer"

# End USER developer
# ------------------------------------------

# Copy script for create projects
# show_msg "Copy script for create projects"
# su $DEVELOPER -c "wget https://raw.githubusercontent.com/PSF1/ateam-docker-drupal-davinci/simple/configs/create-drupal-project.sh"
# su $DEVELOPER -c "mv create-drupal-project.sh /create-drupal-project.sh"
# chmod +x /create-drupal-project.sh

# su $DEVELOPER -c "wget https://raw.githubusercontent.com/PSF1/ateam-docker-drupal-davinci/simple/configs/create-user-drupal-project.sh"
# su $DEVELOPER -c "mv create-user-drupal-project.sh /home/$DEVELOPER/create-user-drupal-project.sh"
# chmod +x /home/$DEVELOPER/create-user-drupal-project.sh

# Set path.
show_msg "Set path"
echo "PATH=\"~/.composer/vendor/bin/:\$PATH\"" >> /home/$DEVELOPER/.bash_profile
su $DEVELOPER -c "source .bash_profile"

# Tests
show_msg "Test php"
su $DEVELOPER -c "php --version"
show_msg "Test phpcs"
su $DEVELOPER -c "~/.composer/vendor/bin/phpcs -i"
show_msg "Test drupal console"
su $DEVELOPER -c "~/.composer/vendor/bin/drupal"
show_msg "Test drush"
su $DEVELOPER -c "~/.composer/vendor/bin/drush status"

echo --------------------------------------------------------------------------------------
echo -
echo - SSH root user password: $SSH_PASS
echo - Mysql root passowrd: $MYSQL_PASS
echo - Folder to projects: /home/$DEVELOPER/Projects
echo -
echo - Added user developer with password developer. Use the user with:
echo - sudo su developer
echo - 
echo - New command tools:
echo - Code style check: drupalcs <folder>
echo - Best practices check: drupalcsp <folder>
su $DEVELOPER -c "ll ~/.composer/vendor/bin"
echo -
echo --------------------------------------------------------------------------------------
echo - Nice Drupal coding !!
echo --------------------------------------------------------------------------------------
