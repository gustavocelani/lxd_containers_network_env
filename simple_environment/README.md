# Simple LXD Environment

## Environment

```
    A1 ----------------------+---------------------- R ---------------------- B1
        eth0                 |                  eth1   eth2                       eth0
        10.10.10.10          |          10.10.10.100   10.10.20.100               10.10.20.10
        2001:db8:2018:A::10  |  2001:db8:2018:A::100   2001:db8:2018:B::100       2001:db8:2018:B::10
                             |
    A2 ----------------------+
        eth0                 |
        10.10.10.20          |
        2001:db8:2018:A::20  |
```

## Script Details

```
################################################################################
#
#       Filename:  simple_lxd_environment.sh
#
#    Description:  Simple LXD Environment General Script.
#                  Run as super user.
#
#       Features:  Generate Base Debian Container
#                  Generate All Environment
#                  Remove Base Debian Container
#                  Remove All Environment
#                  Test Environment
#                  List Containers
#
#       Packages:  lxd
#                  dialog
#
#        Version:  1.1
#        Created:  07/08/2019 20:58:06 PM
#       Revision:  1
#
#         Author:  Gustavo P de O Celani
#
################################################################################
```
