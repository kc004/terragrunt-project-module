#!/bin/sh
apt-get install -y httpd
service start httpd
chkconfig httpd on
echo "hello world, This is Stage" > /var/www/html/index.html
