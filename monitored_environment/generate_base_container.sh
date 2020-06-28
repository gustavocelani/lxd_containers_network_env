#!/bin/bash

###############################################################################
#
#       Filename:  generate_base_container.sh
#
#    Description:  Generate Base Container Script.
#                  Run as super user.
#
#        Version:  1.3
#        Created:  08/10/2019 17:12:36 PM
#       Revision:  1
#
#         Author:  Gustavo P de O Celani
#
################################################################################


# Container Names
NAME_BASE="debian9padrao"


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
# Generate Container Base
################################################################################
echo ""
echo "Generate Container ${NAME_BASE}"

echo "Initializing [ ${NAME_BASE} ] with Debian Stretch"
lxc init images:debian/stretch ${NAME_BASE}

start_container ${NAME_BASE}

echo ""
for COUNT in {5..0}; do printf "\rWaiting to [ ${NAME_BASE} ] start... [ %02d ]" "$COUNT"; sleep 1; done; echo ""

echo ""
echo "Updating [ ${NAME_BASE} ]"
lxc exec ${NAME_BASE} -- /usr/bin/apt update

echo ""
echo "Installing custom packages on [ ${NAME_BASE} ]"
lxc exec ${NAME_BASE} -- /usr/bin/apt install -y tcpdump apt-utils aptitude net-tools inetutils-ping traceroute iptables htop bind9-host dnsutils links vim openssh-server rsyslog

echo ""
echo "Setting up timezone to [ America/Sao_Paulo ]"
lxc exec ${NAME_BASE} -- timedatectl set-timezone "America/Sao_Paulo"

power_off_container ${NAME_BASE}


################################################################################
# Environment
################################################################################

environment_list
