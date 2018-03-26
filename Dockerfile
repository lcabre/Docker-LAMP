FROM php:7.1-apache

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV DATE_TIMEZONE America/Argentina/Buenos_Aires

# setear password root mysql
RUN echo 'mysql-server mysql-server/root_password password docker' | debconf-set-selections
RUN echo 'mysql-server mysql-server/root_password_again password docker' | debconf-set-selections

# PHPMyAdmin
RUN echo 'phpmyadmin phpmyadmin/dbconfig-install boolean true' | debconf-set-selections
RUN echo 'phpmyadmin phpmyadmin/app-password-confirm password docker' | debconf-set-selections
RUN echo 'phpmyadmin phpmyadmin/mysql/admin-pass password docker' | debconf-set-selections
RUN echo 'phpmyadmin phpmyadmin/mysql/app-pass password docker' | debconf-set-selections
RUN echo 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2' | debconf-set-selections

# Install Composer.
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && ln -s $(composer config --global home) /root/composer

# Install PHP extensions and PECL modules.
RUN apt-get update -yqq \
 		&& buildDeps=" \
 			libmemcached-dev  \
 			libz-dev  \
 			libpq-dev  \
 			libjpeg-dev  \
 			libpng12-dev  \
 			libfreetype6-dev  \
 			libmcrypt-dev \
         " \
         && doNotUninstall=" \
            libmemcached11 \
            libmemcachedutil2 \
            libfreetype6 \
            libhashkit2 \
            libjpeg62-turbo \
            libmcrypt4 \
            libpng12-0 \
            libpq5 \
         " \
        && runtimeDeps=" \
            curl \
            git \
            libfreetype6-dev \
            libicu-dev \
            libjpeg-dev \
            libldap2-dev \
            libmemcachedutil2 \
            libpng-dev \
            libpq-dev \
            libxml2-dev \
         " \
 		&& DEBIAN_FRONTEND=noninteractive apt-get install -y --fix-missing nano telnet zip bzip2 wget tar less mysql-server mysql-client phpmyadmin $buildDeps $runtimeDeps \
        && rm -r /var/lib/apt/lists/* \
        && docker-php-ext-install mcrypt zip bcmath calendar iconv mbstring mysqli opcache pdo_mysql pdo_pgsql pgsql soap \
 		&& docker-php-ext-configure gd  \
 				--enable-gd-native-ttf  \
 				--with-jpeg-dir=/usr/lib  \
 				--with-freetype-dir=/usr/include/freetype2 &&  \
 				docker-php-ext-install gd \
 		&& pecl install memcached redis xdebug \
 		&& docker-php-ext-enable memcached redis xdebug \
 		&& rm -rf /tmp/pear \
        && apt-mark manual $doNotUninstall \
        && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $buildDeps

RUN apt-get clean


#RUN sed -ie "s/^bind-address\s*=\s*127\.0\.0\.1$/bind-address = 0.0.0.0/" /etc/mysql/my.cnf
#RUN service mysql start && mysql -uroot -p -e 'USE mysql; UPDATE `user` SET `Host`="%" WHERE `User`="root" AND `Host`="localhost"; DELETE FROM `user` WHERE `Host` != "%" AND `User`="root"; FLUSH PRIVILEGES;'

# XDebug config.
ENV XDEBUGINI_PATH=/usr/local/etc/php/conf.d/xdebug.ini
RUN echo "zend_extension="`find /usr/local/lib/php/extensions/ -iname 'xdebug.so'` > $XDEBUGINI_PATH \
    && echo "xdebug.remote_enable=on" >> $XDEBUGINI_PATH \
    && echo "xdebug.remote_host=192.168.56.1" >> $XDEBUGINI_PATH \
    && echo "xdebug.remote_autostart=on" >> $XDEBUGINI_PATH \
    && echo "xdebug.remote_connect_back=off" >> $XDEBUGINI_PATH \
    && echo "xdebug.remote_handler=dbgp" >> $XDEBUGINI_PATH \
    && echo "xdebug.profiler_enable=0" >> $XDEBUGINI_PATH \
    && echo "xdebug.profiler_output_dir='/var/www/html'" >> $XDEBUGINI_PATH \
    && echo "xdebug.remote_port=9000" >> $XDEBUGINI_PATH

RUN chown -R $APACHE_RUN_USER:$APACHE_RUN_GROUP /var/www/html/

COPY config/php.ini /usr/local/etc/php/
COPY src /var/www/html/

RUN a2enmod rewrite
ADD config/apache-config.conf /etc/apache2/sites-enabled/000-default.conf

WORKDIR /var/www/html/

ADD config/run.sh /usr/sbin/
RUN chmod 777 /usr/sbin/run.sh

CMD ["/usr/sbin/run.sh"]