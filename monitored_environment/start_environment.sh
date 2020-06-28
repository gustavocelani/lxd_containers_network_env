#!/bin/bash

###############################################################################
#
#       Filename:  start_environment.sh
#
#    Description:  Monitored LXD Environment Start Script.
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
# Start a Container
# $1 Container Name
#
start_container()
{
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
# Start Environment
################################################################################
start_container ${NAME_FIREWALL}
start_container ${NAME_WWW1}
start_container ${NAME_WWW2}
start_container ${NAME_LOG}
start_container ${NAME_GERENCIA}
start_container ${NAME_SSH}
start_container ${NAME_PROXY}


################################################################################
# Environment
################################################################################

environment_list
