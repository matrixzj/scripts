#!/usr/bin/expect 
set timeout 5
set consoleid [lindex $argv 0]
set hostname [lindex $argv 1]
set ipaddr [lindex $argv 2]
    
spawn virsh console --force $consoleid
expect "Escape character" 
send "\n"
expect "login:" 
send "root\n"
expect  "Password:" 
send "redhat\n"
expect "#"
#send "df -h\n"
#expect "#"
send "echo $hostname.example.net > /etc/hostname\n"
expect "#"
send "sed -i \"/^IPADDR/s/\\(IPADDR=\\).*/\\1$ipaddr/\" /etc/sysconfig/network-scripts/ifcfg-eth0\n"
expect "#"
send "sed -i \"/^ONBOOT/s/ONBOOT=no/ONBOOT=yes/\" /etc/sysconfig/network-scripts/ifcfg-eth0\n"
expect "#"
send "echo Hostname=$hostname >> /etc/zabbix/zabbix_agentd.conf\n"
expect "#"
send "logout\n"
#send "reboot\n"
# send "\x1d\n"
expect "login:"
send "\x1d\n"
# interact

