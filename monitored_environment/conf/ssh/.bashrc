
# SSH Alias - Network DMZ
alias ssh-ssh='ssh -i /ssh_user/.ssh/ssh_ssh_key ssh_user@172.0.10.10 -p 4578'
alias ssh-proxy='ssh -i /ssh_user/.ssh/ssh_ssh_key proxy_user@172.0.10.20 -p 4578'

# SSH Alias - Network SERVERS
alias ssh-log='ssh -i /ssh_user/.ssh/ssh_ssh_key log_user@172.0.20.10 -p 4578'
alias ssh-gerencia='ssh -i /ssh_user/.ssh/ssh_ssh_key gerencia_user@172.0.20.20 -p 4578'

# SSH Alias - Network WEB
alias ssh-www1='ssh -i /ssh_user/.ssh/ssh_ssh_key www1_user@172.0.30.10 -p 4578'
alias ssh-www2='ssh -i /ssh_user/.ssh/ssh_ssh_key www2_user@172.0.30.20 -p 4578'

# fail2ban
alias log-fail2ban='tail -f /var/log/fail2ban.log'
