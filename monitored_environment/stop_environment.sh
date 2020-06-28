#!/bin/bash

###############################################################################
#
#       Filename:  stop_environment.sh
#
#    Description:  Monitored LXD Environment Stop Script.
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
# Power off a Container
# $1 Container Name
#
power_off_container()
{
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
# Stop Environment
################################################################################
power_off_container ${NAME_FIREWALL}
power_off_container ${NAME_WWW1}
power_off_container ${NAME_WWW2}
power_off_container ${NAME_LOG}
power_off_container ${NAME_GERENCIA}
power_off_container ${NAME_SSH}
power_off_container ${NAME_PROXY}


################################################################################
# Environment
################################################################################

environment_list
