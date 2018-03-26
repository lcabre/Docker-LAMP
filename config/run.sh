#!/bin/bash

# Run Postfix
#/usr/sbin/postfix start

sed -i "s/dbserver=''/dbserver='127.0.0.1'/" /etc/phpmyadmin/config-db.php
sed -i "s/dbuser='phpmyadmin'/dbuser='root'/" /etc/phpmyadmin/config-db.php

# Run Mysql
/usr/bin/mysqld_safe --timezone=${DATE_TIMEZONE}&

# Run Apache:
#/usr/sbin/apachectl -DFOREGROUND -k start -e debug
&>/dev/null /usr/sbin/apachectl -DFOREGROUND -k start