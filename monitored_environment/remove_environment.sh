#!/bin/bash

###############################################################################
#
#       Filename:  remove_environment.sh
#
#    Description:  Monitored LXD Environment Removement Script.
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
# Removes a container
# $1: Container Name
#
remove_container()
{
    clear
    print_logo

    power_off_container $1
    for COUNT in {3..0}; do printf "\rWaiting to [ $1 ] power off... [ %02d ]" "$COUNT"; sleep 1; done; echo ""

    echo "Removing [ $1 ]"
    lxc delete $1
}


#
# Removes a network
# $1: Network Name
#
remove_network()
{
    clear
    print_logo

    echo "Removing [ $1 ]"
    lxc network delete $1
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
# Remove Environment
################################################################################
remove_container ${NAME_FIREWALL}
remove_container ${NAME_WWW1}
remove_container ${NAME_WWW2}
remove_container ${NAME_LOG}
remove_container ${NAME_GERENCIA}
remove_container ${NAME_SSH}
remove_container ${NAME_PROXY}

remove_network ${NETWORK_DMZ}
remove_network ${NETWORK_SERVERS}
remove_network ${NETWORK_WEB}


################################################################################
# Environment
################################################################################

environment_list
