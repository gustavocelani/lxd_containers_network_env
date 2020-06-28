# Monitored LXD Environment

## Environment


![Alt text](doc/topology_2.jpg?raw=true "Topology")


## Containers


### SSH

This machine is on DMZ network that has access to internet under firewall rules. It is responsable to access all another machines using SSHv2.


### Proxy

This machine is on DMZ network that has access to internet under firewall rules. It provides a HTTPS Reverse Proxy with Load Balancer on port 443 powered by Nginx.


### WWW1 and WWW2

This machines are on WEB network that has no access to internet under firewall rules. Each one provides a HTTP Web Server on port 80 powered by Nginx.


### Log Server

This machine is on SERVERS network that has no access to internet under firewall rules. It provides a centralized log server powered by Rsyslog and LogAnalyzer.


### Gerencia Server

This machine is on SERVERS network that has no access to internet under firewall rules. It provides a centralized network management server powered by Zabbix.


## Hardening

### SSH

- SSH Protol 2
- Disabling root login
- Client sessions
	- Client Alive Interval: 300
	- Client Alive Count Max: 3
- Avoiding default port (22 -> 4578)
- Disabling X11 forwarding
- Only 'ssh_user' allowed
- 3-Factor Authentication
	- Password
	- RSA Key
	- Challenge PAM with Google-Authenticator
- Fail2ban
	- Selected ban time
	- 3 Max retry
	- Alias to watch logs: `$ log-fail2ban`
- Firewall rules


#### Proxy

- TLS over HTTP (HTTPS)
- Load Balancer for WWW1 and WWW2
- Reverse Proxy
- DDoS Prevention
- Firewall rules

#### Log Server

- Avoiding Rsyslog default port (514 -> 5689)
- Allowed networks whitelist
- Log rotation weekly
- Firewall rules


## Installation Guide (Overview)

Install LXD/LXC (https://linuxcontainers.org/lxd/introduction/)
```
$ sudo apt-get install lxd
```

Clone the repository
```
$ git clone https://github.com/gustavocelani/shell_scripts.git
```

As super user, run the main script [ monitored_lxd_environment.sh ]
```
$ sudo su
# cd shell_scripts/lxd/monitored_environment/
# ./monitored_lxd_environment.sh
```

Wait the script runs...

Set up SSH container user
```
Setting up user with password
Adding user `ssh_user' ...
Adding new group `ssh_user' (1000) ...
Adding new user `ssh_user' (1000) with group `ssh_user' ...
The home directory `/home/ssh_user' already exists.  Not copying from `/etc/skel'.
Enter new UNIX password:  **ssh_user**
Retype new UNIX password: **ssh_user**

Enter the new value, or press ENTER for the default
	Full Name   []: **SSH User**
	Room Number []: **0**
	Work Phone  []: **0**
	Home Phone  []: **0**
	Other       []: **0**
Is the information correct? [Y/n] **y**
```

Set up Google-Authenticator
```
Do you want authentication tokens to be time-based (y/n) **y**

#
# Read the QR code with you Google-Authenticator App
#

Do you want me to update your "/home/ssh_user/.google_authenticator" file (y/n) **y**

Do you want to disallow multiple uses of the same authentication
token? This restricts you to one login about every 30s, but it increases
your chances to notice or even prevent man-in-the-middle attacks (y/n) **y**

By default, tokens are good for 30 seconds. In order to compensate for
possible time-skew between the client and the server, we allow an extra
token before and after the current time. If you experience problems with
poor time synchronization, you can increase the window from its default
size of +-1min (window size of 3) to about +-4min (window size of
17 acceptable tokens).
Do you want to do so? (y/n) **y**

If the computer that you are logging into isn't hardened against brute-force
login attempts, you can enable rate-limiting for the authentication module.
By default, this limits attackers to no more than 3 login attempts every 30s.
Do you want to enable rate-limiting (y/n) **y**
```

Set up Proxy Self-Signed x509 Certificate Authority
```
Country Name (2 letter code)                          [AU]: **BR**
State or Province Name (full name)            [Some-State]: **Sao Paulo**
Locality Name (eg, city)                                []: **Campinas**
Organization Name (eg, company) [Internet Widgits Pty Ltd]: **UNICAMP**
Organizational Unit Name (eg, section)                  []: **INF574**
Common Name (e.g. server FQDN or YOUR name)             []: **PROXY_CA**
Email Address                                           []: **proxy@mail.com**
```

Expected Result
```
+---------------+---------+----------------------+----------------------------+
|     NAME      |  STATE  |         IPV4         |            IPV6            |
+---------------+---------+----------------------+----------------------------+
| debian9padrao | STOPPED |                      |                            |
+---------------+---------+----------------------+----------------------------+
| firewall      | RUNNING | 172.0.30.100 (eth3)  | 2001:db8:574:c::100 (eth3) |
|               |         | 172.0.20.100 (eth2)  | 2001:db8:574:b::100 (eth2) |
|               |         | 172.0.10.100 (eth1)  | 2001:db8:574:a::100 (eth1) |
|               |         | 10.166.181.48 (eth0) |                            |
+---------------+---------+----------------------+----------------------------+
| gerencia      | RUNNING | 172.0.20.20 (eth0)   | 2001:db8:574:b::20 (eth0)  |
+---------------+---------+----------------------+----------------------------+
| log           | RUNNING | 172.0.20.10 (eth0)   | 2001:db8:574:b::10 (eth0)  |
+---------------+---------+----------------------+----------------------------+
| proxy         | RUNNING | 172.0.10.20 (eth0)   | 2001:db8:574:a::20 (eth0)  |
+---------------+---------+----------------------+----------------------------+
| ssh           | RUNNING | 172.0.10.10 (eth0)   | 2001:db8:574:a::10 (eth0)  |
+---------------+---------+----------------------+----------------------------+
| www1          | RUNNING | 172.0.30.10 (eth0)   | 2001:db8:574:c::10 (eth0)  |
+---------------+---------+----------------------+----------------------------+
| www2          | RUNNING | 172.0.30.20 (eth0)   | 2001:db8:574:c::20 (eth0)  |
+---------------+---------+----------------------+----------------------------+

+----------------+----------+---------+-------------+---------+
|      NAME      |   TYPE   | MANAGED | DESCRIPTION | USED BY |
+----------------+----------+---------+-------------+---------+
| enp2s0f1       | physical | NO      |             | 0       |
+----------------+----------+---------+-------------+---------+
| lxcbr0         | bridge   | NO      |             | 0       |
+----------------+----------+---------+-------------+---------+
| lxdbr0         | bridge   | YES     |             | 2       |
+----------------+----------+---------+-------------+---------+
| networkDMZ     | bridge   | YES     |             | 3       |
+----------------+----------+---------+-------------+---------+
| networkServers | bridge   | YES     |             | 3       |
+----------------+----------+---------+-------------+---------+
| networkWeb     | bridge   | YES     |             | 3       |
+----------------+----------+---------+-------------+---------+
| wlp3s0         | physical | NO      |             | 0       |
+----------------+----------+---------+-------------+---------+
```

## Usage

### Login

Login SSH Container with 3-factor authentication
```
# ssh -i ./conf/ssh/ssh_ssh_key ssh_user@172.0.10.10 -p 4578
Password: **ssh_user**
Verification code: *current google-authenticator code*
```

Now all containers are available using follow aliases from SSH Container:
```
# Network DMZ
$ ssh-ssh
$ ssh-proxy

# Network SERVERS
$ ssh-log
$ ssh-gerencia

# Network WEB
$ ssh-www1
$ ssh-www2
```

### Management Accessments

From host machine:

- Load Balancer of web servers
	- `https://172.0.10.20`
	- `https://172.0.10.20/www`
- WWW1 Web Server
	- `https://172.0.10.20/www1`
- WWW2 Web Server
	- `https://172.0.10.20/www2`
- LogAnalyzer
	- `https://172.0.10.20/log`
- Zabbix
	- `https://172.0.10.20/gerencia`

