#!/bin/bash

###############################################################################
#
#       Filename:  monitored_lxd_environment.sh
#
#    Description:  Monitored LXD Environment General Script.
#                  Run as super user.
#
#        Version:  1.4
#        Created:  08/10/2019 17:12:36 PM
#       Revision:  1
#
#         Author:  Gustavo P de O Celani
#
################################################################################


# Container Names
NAME_BASE="debian9padrao"
NAME_WWW1="www1"
NAME_WWW2="www2"
NAME_LOG="log"
NAME_GERENCIA="gerencia"
NAME_PROXY="proxy"
NAME_SSH="ssh"
NAME_FIREWALL="firewall"

# Network Names
NETWORK_DMZ="networkDMZ"
NETWORK_SERVERS="networkServers"
NETWORK_WEB="networkWeb"


#
# Print Logo
#
print_logo()
{
    echo ""
    echo " ___ _   _ _____   ____ _____ _  _   "
    echo "|_ _| \\ | |  ___| | ___|___  | || |  "
    echo " | ||  \\| | |_    |___ \\  / /| || |_ "
    echo " | || |\\  |  _|    ___) |/ / |__   _|"
    echo "|___|_| \\_|_|     |____//_/     |_|  "
    echo ""
}


#
# Generate Networks
#
generate_networks()
{
    clear
    print_logo

	echo ""
	echo "Generate Networks"

    echo ""
    echo "Generating network [ ${NETWORK_DMZ} ] ..."
    lxc network create ${NETWORK_DMZ} ipv6.address=2001:db8:574:A::1/64 ipv4.address=172.0.10.1/24 ipv4.nat=false ipv4.dhcp=false

    echo "Generating network [ ${NETWORK_SERVERS} ] ..."
    lxc network create ${NETWORK_SERVERS} ipv6.address=2001:db8:574:B::1/64 ipv4.address=172.0.20.1/24 ipv4.nat=false ipv4.dhcp=false

    echo "Generating network [ ${NETWORK_WEB} ] ..."
    lxc network create ${NETWORK_WEB} ipv6.address=2001:db8:574:C::1/64 ipv4.address=172.0.30.1/24 ipv4.nat=false ipv4.dhcp=false
}


#
# Generate Container Firewall
#
generate_container_firewall()
{
    clear
    print_logo

	echo ""
	echo "Generate Container ${NAME_FIREWALL}"

    echo ""
    echo "Cloning [ ${NAME_BASE} ] to [ ${NAME_FIREWALL} ]"
    lxc copy ${NAME_BASE} ${NAME_FIREWALL}

    echo ""
    echo "Attaching network [ ${NETWORK_DMZ} ] on interface [ eth1 ]"
    lxc network attach ${NETWORK_DMZ} ${NAME_FIREWALL} eth1

    echo "Attaching network [ ${NETWORK_SERVERS} ] on interface [ eth2 ]"
    lxc network attach ${NETWORK_SERVERS} ${NAME_FIREWALL} eth2

    echo "Attaching network [ ${NETWORK_WEB} ] on interface [ eth3 ]"
    lxc network attach ${NETWORK_WEB} ${NAME_FIREWALL} eth3

    start_container ${NAME_FIREWALL}
    for COUNT in {5..0}; do printf "\rWaiting to [ ${NAME_FIREWALL} ] start... [ %02d ]" "$COUNT"; sleep 1; done; echo ""

    echo ""
    echo "Pushing rsyslog client configuration files..."
    echo "./conf/general/rsyslog.conf    --->   ${NAME_FIREWALL}/etc/rsyslog.conf"
    lxc file push ./conf/general/rsyslog.conf ${NAME_FIREWALL}/etc/rsyslog.conf
    echo "./conf/general/logrotate.conf    --->   ${NAME_FIREWALL}/etc/logrotate.conf"
    lxc file push ./conf/general/logrotate.conf ${NAME_FIREWALL}/etc/logrotate.conf

    echo ""
    echo "./conf/general/zabbix-release_4.4-1+stretch_all.deb    --->   ${NAME_FIREWALL}/tmp/"
    lxc file push ./conf/general/zabbix-release_4.4-1+stretch_all.deb ${NAME_FIREWALL}/tmp/
    echo "Installing zabbix 4.4.1"
    lxc exec ${NAME_FIREWALL} -- dpkg -i /tmp/zabbix-release_4.4-1+stretch_all.deb
    echo "Updating packages"
    lxc exec ${NAME_FIREWALL} -- apt-get update

    echo ""
    echo "Installing zabbix-agent"
    lxc exec ${NAME_FIREWALL} -- apt-get install -y zabbix-agent
    echo "Enabling zabbix-agent on startup"
    lxc exec ${NAME_FIREWALL} -- update-rc.d zabbix-agent enable
    echo "./conf/general/zabbix_agentd.conf    --->   ${NAME_FIREWALL}/etc/zabbix/zabbix_agentd.conf"
    lxc file push ./conf/general/zabbix_agentd.conf ${NAME_FIREWALL}/etc/zabbix/zabbix_agentd.conf --mode 0644

    echo ""
    echo "Pushing configuration files..."
    echo "./conf/${NAME_FIREWALL}/interfaces    --->   ${NAME_FIREWALL}/etc/network/interfaces"
    lxc file push ./conf/${NAME_FIREWALL}/interfaces ${NAME_FIREWALL}/etc/network/interfaces
    echo "./conf/${NAME_FIREWALL}/sysctl.conf   --->   ${NAME_FIREWALL}/etc/sysctl.conf"
    lxc file push ./conf/${NAME_FIREWALL}/sysctl.conf ${NAME_FIREWALL}/etc/sysctl.conf
    echo "./conf/${NAME_FIREWALL}/rc.local      --->   ${NAME_FIREWALL}/etc/rc.local"
    lxc file push ./conf/${NAME_FIREWALL}/rc.local ${NAME_FIREWALL}/etc/rc.local
    echo "./conf/${NAME_FIREWALL}/sshd_config   --->   ${NAME_FIREWALL}/etc/ssh/sshd_config"
    lxc file push ./conf/${NAME_FIREWALL}/sshd_config ${NAME_FIREWALL}/etc/ssh/sshd_config

    echo ""
    echo "Rebooting ${NAME_FIREWALL}"
    lxc exec ${NAME_FIREWALL} -- reboot

    for COUNT in {3..0}; do printf "\rWaiting to [ $1 ] start... [ %02d ]" "$COUNT"; sleep 1; done; echo ""

    echo ""
    echo "Setting up NAT to between DMZ Network and eth0"
    lxc exec ${NAME_FIREWALL} -- iptables -t nat -A POSTROUTING --source 172.0.10.0/24 --out-interface eth0 -j MASQUERADE
}


#
# Generate Container
#
# $1: Container Name
# $2: Network Name to be attached on eth0 interface
#
generate_container()
{
    clear
    print_logo

    echo ""
	echo "Generate Container [ $1 ]"

    echo ""
    echo "Cloning [ ${NAME_BASE} ] to [ $1 ]"
    lxc copy ${NAME_BASE} $1

    start_container $1
    for COUNT in {5..0}; do printf "\rWaiting to [ $1 ] start... [ %02d ]" "$COUNT"; sleep 1; done; echo ""

    echo ""
    echo "Creating user [ $1_user ]"
    lxc exec $1 -- adduser --disabled-password --gecos "" $1_user

    echo ""
    echo "Pushing rsyslog client configuration files..."
    echo "./conf/general/rsyslog.conf    --->   $1/etc/rsyslog.conf"
    lxc file push ./conf/general/rsyslog.conf $1/etc/rsyslog.conf
    echo "./conf/general/logrotate.conf    --->   $1/etc/logrotate.conf"
    lxc file push ./conf/general/logrotate.conf $1/etc/logrotate.conf

    echo ""
    echo "./conf/general/zabbix-release_4.4-1+stretch_all.deb    --->   $1/tmp/"
    lxc file push ./conf/general/zabbix-release_4.4-1+stretch_all.deb $1/tmp/
    echo "Installing zabbix 4.4.1"
    lxc exec $1 -- dpkg -i /tmp/zabbix-release_4.4-1+stretch_all.deb
    echo "Updating packages"
    lxc exec $1 -- apt-get update
    echo "Upgrading packages"
    lxc exec $1 -- apt-get upgrade -y

    if [[ "$1" != "${NAME_GERENCIA}" ]]
    then
        echo ""
        echo "Installing zabbix-agent"
        lxc exec $1 -- apt-get install -y zabbix-agent
        echo "Enabling zabbix-agent on startup"
        lxc exec $1 -- update-rc.d zabbix-agent enable
        echo "./conf/general/zabbix_agentd.conf    --->   $1/etc/zabbix/zabbix_agentd.conf"
        lxc file push ./conf/general/zabbix_agentd.conf $1/etc/zabbix/zabbix_agentd.conf --mode 0644
    fi
    
    echo ""
    echo "Executing custom setup on [ $1 ]"
    case $1 in

        ## SSH Container
        ${NAME_SSH})

            echo ""
            echo "Setting up user with password"
            lxc exec $1 -- userdel $1_user
            lxc exec $1 -- adduser $1_user

            echo ""
            echo "Installing fail2ban and libpam-google-authenticator"
            lxc exec $1 -- /usr/bin/apt install -y fail2ban libpam-google-authenticator

            echo ""
            echo "Setting up SSH alias"
            echo "./conf/$1/.bashrc    --->   $1/root/.bashrc"
            lxc file push ./conf/$1/.bashrc $1/root/.bashrc
            echo "./conf/$1/.bashrc    --->   $1/home/$1_user/.bashrc.alias"
            lxc file push ./conf/$1/.bashrc $1/home/$1_user/
            lxc exec $1 -- cat $1/home/$1_user/.bashrc.alias >> $1/home/$1_user/.bashrc

            echo ""
            echo "Setting up fail2ban"
            echo "./conf/$1/jail.local    --->   $1/etc/fail2ban/"
            lxc file push ./conf/$1/jail.local $1/etc/fail2ban/
            echo "./conf/$1/fail2ban.local    --->   $1/etc/fail2ban/"
            lxc file push ./conf/$1/fail2ban.local $1/etc/fail2ban/
            echo "Setting up fail2ban logfile ownership"
            lxc exec $1 -- chown $1_user:$1_user /var/log/fail2ban.log
            echo "Restarting fail2ban service"
            lxc exec $1 -- service fail2ban restart

            echo ""
            echo "Setting up libpam-google-authenticator"
            echo "./conf/$1/sshd    --->   $1/etc/pam.d/sshd"
            lxc file push ./conf/$1/sshd $1/etc/pam.d/sshd
            echo "Starting libpam-google-authenticator"
            lxc exec $1 -- runuser -l  $1_user -c 'google-authenticator'
        ;;
        
        # WWW1 and WWW2 Containers
        ${NAME_WWW1}|${NAME_WWW2})

            echo ""
            echo "Installing nginx"
            lxc exec $1 -- /usr/bin/apt install -y nginx

            echo ""
            echo "Setting up Nginx HTTP Web Server"
            echo "./conf/$1/default    --->   $1/etc/nginx/sites-enabled/"
            lxc file push ./conf/$1/default $1/etc/nginx/sites-enabled/
            echo "./conf/$1/index.html    --->   $1/usr/share/nginx/html/index.html"
            lxc file push ./conf/$1/index.html $1/usr/share/nginx/html/index.html
        ;;

        # Proxy Container
        ${NAME_PROXY})

            echo ""
            echo "Installing nginx"
            lxc exec $1 -- /usr/bin/apt install -y nginx

            echo ""
            echo "Creating Nginx Key Certificate Authority"
            openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ./conf/$1/$1_nginx.key -out ./conf/$1/$1_nginx.crt

            echo ""
            echo "Setting up Nginx HTTPS Reverse Proxy and Load Balancer"
            lxc exec $1 -- mkdir /etc/nginx/ssl
            echo "./conf/$1/$1_nginx.key    --->   $1/etc/nginx/ssl/"
            lxc file push ./conf/$1/$1_nginx.key $1/etc/nginx/ssl/
            echo "./conf/$1/$1_nginx.crt    --->   $1/etc/nginx/ssl/"
            lxc file push ./conf/$1/$1_nginx.crt $1/etc/nginx/ssl/
            echo "./conf/$1/default    --->   $1/etc/nginx/sites-enabled/"
            lxc file push ./conf/$1/default $1/etc/nginx/sites-enabled/
        ;;

        # Log Server Container
        ${NAME_LOG})

            echo ""
            echo "Installing apache2 libapache2-mod-php mysql-server php7.0-mysql php7.0 php7.0-mysql php7.0-curl php7.0-gd php7.0-json php7.0-opcache php7.0-xml mcrypt php7.0-mcrypt"
            lxc exec $1 -- /usr/bin/apt install -y apache2 libapache2-mod-php mysql-server php7.0-mysql php7.0 php7.0-mysql php7.0-curl php7.0-gd php7.0-json php7.0-opcache php7.0-xml mcrypt php7.0-mcrypt

            echo ""
            echo "Installing loganalyzer"
            echo "./conf/$1/loganalyzer-4.1.6.tar.gz    --->   $1/tmp/"
            lxc file push ./conf/$1/loganalyzer-4.1.6.tar.gz $1/tmp/
            echo "Extracting loganalyzer package"
            lxc exec $1 -- tar -xzvf /tmp/loganalyzer-4.1.6.tar.gz -C /tmp
            echo "Copying source content to loganalyzer package"
            lxc exec $1 -- cp -rf /tmp/loganalyzer-4.1.6/src /var/www/html/loganalyzer
            echo "./conf/$1/config.php    --->   $1/var/www/html/loganalyzer/config.php"
            lxc file push ./conf/$1/config.php $1/var/www/html/loganalyzer/config.php
            echo "Setting up owner for config.php"
            lxc exec $1 -- chown $1_user:$1_user /var/www/html/loganalyzer/config.php
            echo "Setting up permission for config.php"
            lxc exec $1 -- chmod 666 /var/www/html/loganalyzer/config.php
            echo "Setting up owner for loganalyzer directory"
            lxc exec $1 -- chown $1_user:$1_user -R /var/www/html/loganalyzer/

            echo ""
            echo "Pushing rsyslog server configuration files..."
            echo "./conf/$1/rsyslog.conf    --->   $1/etc/rsyslog.conf"
            lxc file push ./conf/$1/rsyslog.conf $1/etc/rsyslog.conf
        ;;

        # Gerencia Server Container
        ${NAME_GERENCIA})

            echo ""
            echo "Updating package sources list"
            echo "./conf/$1/sources.list    --->   $1/etc/apt/sources.list"
            lxc file push ./conf/$1/sources.list $1/etc/apt/sources.list --mode 0755
            echo "Updating packages"
            lxc exec $1 -- apt-get update
            echo "Upgrading packages"
            lxc exec $1 -- apt-get upgrade -y

            echo "Installing zabbix-server-mysql"
            lxc exec $1 -- apt-get install -y zabbix-server-mysql
            echo "./conf/$1/zabbix_server.conf    --->   $1/etc/zabbix/zabbix_server.conf"
            lxc file push ./conf/$1/zabbix_server.conf $1/etc/zabbix/zabbix_server.conf --mode 0644

            echo ""
            echo "Installing zabbix-frontend-php zabbix-apache-conf"
            lxc exec $1 -- apt-get install -y zabbix-frontend-php zabbix-apache-conf
            echo "./conf/$1/php.ini    --->   $1/etc/php/7.0/apache2/php.ini"
            lxc file push ./conf/$1/php.ini $1/etc/php/7.0/apache2/php.ini --mode 0644
            echo "./conf/$1/zabbix_db_setup.sh    --->   $1/root/"
            lxc file push ./conf/$1/zabbix_db_setup.sh $1/root/ --mode 0755

            echo ""
            echo "Setting up Zabbix Database"
            lxc exec $1 -- /root/zabbix_db_setup.sh

            echo ""
            echo "Installing zabbix-agent"
            lxc exec $1 -- apt-get install -y zabbix-agent
            echo "Enabling zabbix-agent on startup"
            lxc exec $1 -- update-rc.d zabbix-agent enable
        ;;
    esac

    echo ""
    echo "Pushing default configuration files..."
    echo "./conf/$1/interfaces    --->   $1/etc/network/interfaces"
    lxc file push ./conf/$1/interfaces $1/etc/network/interfaces
    echo "./conf/$1/sshd_config   --->   $1/etc/ssh/sshd_config"
    lxc file push ./conf/$1/sshd_config $1/etc/ssh/sshd_config

    power_off_container $1
    for COUNT in {3..0}; do printf "\rWaiting to [ $1 ] power off... [ %02d ]" "$COUNT"; sleep 1; done; echo ""

    echo ""
    echo "Attaching network [ $2 ] on interface [ eth0 ]"
    lxc network attach $2 $1 eth0
    
    start_container $1
}


#
# Configure_ssh_keys
#
configure_ssh_keys()
{
    for CONTAINER in ${NAME_SSH} ${NAME_WWW1} ${NAME_WWW2} ${NAME_PROXY} ${NAME_LOG} ${NAME_GERENCIA} ${NAME_FIREWALL}
    do
        clear
        print_logo

        echo ""
        echo "Configuring SSH for [ ${CONTAINER} ]"

        echo ""
        echo "Generating Key Pair"
        ssh-keygen -t rsa -b 4096 -N '' -f ./conf/${CONTAINER}/${CONTAINER}_ssh_key

        echo ""
        echo "Creating /${CONTAINER}_user/.ssh directory"
        lxc exec ${CONTAINER} -- mkdir -p /${CONTAINER}_user/.ssh

        echo ""
        echo "./conf/${CONTAINER}/${CONTAINER}_ssh_key        --->   ${CONTAINER}/${CONTAINER}_user/.ssh/"
        lxc file push ./conf/${CONTAINER}/${CONTAINER}_ssh_key ${CONTAINER}/${CONTAINER}_user/.ssh/
        echo "./conf/${CONTAINER}/${CONTAINER}_ssh_key.pub    --->   ${CONTAINER}/${CONTAINER}_user/.ssh/"
        lxc file push ./conf/${CONTAINER}/${CONTAINER}_ssh_key.pub ${CONTAINER}/${CONTAINER}_user/.ssh/
        echo "./conf/${NAME_SSH}/${NAME_SSH}_ssh_key.pub   --->   ${CONTAINER}/${CONTAINER}_user/.ssh/authorized_keys"
        lxc file push ./conf/${NAME_SSH}/${NAME_SSH}_ssh_key.pub ${CONTAINER}/${CONTAINER}_user/.ssh/authorized_keys

        echo ""
        echo "Setting up authorized_keys permission"
        lxc exec ${CONTAINER} -- chown ${CONTAINER}_user:${CONTAINER}_user /${CONTAINER}_user/.ssh/${CONTAINER}_ssh_key
        lxc exec ${CONTAINER} -- chown ${CONTAINER}_user:${CONTAINER}_user /${CONTAINER}_user/.ssh/${CONTAINER}_ssh_key.pub
        lxc exec ${CONTAINER} -- chown ${CONTAINER}_user:${CONTAINER}_user /${CONTAINER}_user/.ssh/authorized_keys
        lxc exec ${CONTAINER} -- chmod 0600 /${CONTAINER}_user/.ssh/authorized_keys

        echo ""
        echo "Restarting SSH Service"
        lxc exec ${CONTAINER} -- service ssh restart
        lxc exec ${CONTAINER} -- service sshd restart

    done
}


#
# Power off a Container
# $1 Container Name
#
power_off_container()
{
    echo ""
    echo "Turning off [ $1 ]"
    lxc exec $1 -- /sbin/poweroff
}


#
# Start a Container
# $1 Container Name
#
start_container()
{
    echo ""
    echo "Starting [ $1 ]"
    lxc start $1
}


#
# List Environment
#
environment_list()
{
    clear
    print_logo

    lxc list
    echo ""
    lxc network list

    echo ""
    read -p "Press enter to continue..."
    echo ""
}


################################################################################
# Main Loop
################################################################################
clear
print_logo


################################################################################
# Networks
################################################################################

#
# Generate Networks
#
# DMZ
# ===
# IPv4: 172.0.10.1/24
# IPv6: 2001:db8:574:A::1/64
#
# SERVERS
# =======
# IPv4: 172.0.20.1/24
# IPv6: 2001:db8:574:B::1/64
#
# WEB
# ===
# IPv4: 172.0.30.1/24
# IPv6: 2001:db8:574:C::1/64
#
generate_networks


################################################################################
# Firewall Container
################################################################################

#
# Generate Firewall Container
# Check network information on [ ./conf/firewall/interfaces ]
#
# eth0
# ====
# DHCP
#
# eth1
# ====
# Network: DMZ
# IPv4:    172.0.10.100/24
# IPv6:    2001:db8:574:A::100/64
#
# eth2
# ====
# Network: SERVERS
# IPv4:    172.0.20.100/24
# IPv6:    2001:db8:574:B::100/64
#
# eth3
# ====
# Network: WEB
# IPv4:    172.0.30.100/24
# IPv6:    2001:db8:574:B::100/64
#
generate_container_firewall


################################################################################
# Network: WEB
################################################################################

#
# Generate Container www1
# Check network information on [ ./conf/www1/interfaces ]
#
# eth0
# ====
# Network: WEB
# IPv4:    172.0.30.10/24
# IPv6:    2001:db8:574:C::10/64
#
generate_container ${NAME_WWW1} ${NETWORK_WEB}

#
# Generate Container www2
# Check network information on [ ./conf/www2/interfaces ]
#
# eth0
# ====
# Network: WEB
# IPv4:    172.0.30.20/24
# IPv6:    2001:db8:574:C::20/64
#
generate_container ${NAME_WWW2} ${NETWORK_WEB}


################################################################################
# Network: SERVERS
################################################################################

#
# Generate Container Log
# Check network information on [ ./conf/log/interfaces ]
#
# eth0
# ====
# Network: SERVERS
# IPv4:    172.0.20.10/24
# IPv6:    2001:db8:574:B::10/64
#
generate_container ${NAME_LOG} ${NETWORK_SERVERS}

#
# Generate Container Gerencia
# Check network information on [ ./conf/gerencia/interfaces ]
#
# eth0
# ====
# Network: SERVERS
# IPv4:    172.0.20.20/24
# IPv6:    2001:db8:574:B::20/64
#
generate_container ${NAME_GERENCIA} ${NETWORK_SERVERS}


################################################################################
# Network: DMZ
################################################################################

#
# Generate Container SSH
# Check network information on [ ./conf/ssh/interfaces ]
#
# eth0
# ====
# Network: DMZ
# IPv4:    172.0.10.10/24
# IPv6:    2001:db8:574:A::10/64
#
generate_container ${NAME_SSH} ${NETWORK_DMZ}

#
# Generate Container Proxy
# Check network information on [ ./conf/proxy/interfaces ]
#
# eth0
# ====
# Network: DMZ
# IPv4:    172.0.10.20/24
# IPv6:    2001:db8:574:A::20/64
#
generate_container ${NAME_PROXY} ${NETWORK_DMZ}


################################################################################
# SSH Keys Setup
################################################################################
configure_ssh_keys


################################################################################
# Environment
################################################################################

environment_list
