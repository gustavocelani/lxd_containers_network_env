#!/bin/bash

echo "create database zabbix character set utf8 collate utf8_bin;" | mysql
echo "grant all privileges on zabbix.* to zabbix@localhost identified by 'password';" | mysql 
zcat /usr/share/doc/zabbix-server-mysql/create.sql.gz | mysql -uzabbix -ppassword zabbix

update-rc.d zabbix-server enable
update-rc.d apache2 enable

service zabbix-server start
service apache2 restart
