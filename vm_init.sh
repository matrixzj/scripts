#!/usr/bin/expect 
set timeout 5
set consoleid [lindex $argv 0]
set hostname [lindex $argv 1]
set ipaddr [lindex $argv 2]
    
spawn virsh console --force $consoleid
expect "Escape character" 
send "\n" ;
expect "login:" 
send "root\n"
expect  "Password:" 
send "C@st20!6fw\n"
expect "#"
send "df -h\n"
expect "#"
send "echo $hostname > /tmp/hostname\n"
expect "#"
send "sed -i \"/^IPADDR/s/\\(IPADDR=\\).*/\\1$ipaddr/\" /tmp/ifcfg-eth0\n"
send "exit\n"
expect "login:"
send "\x1d"
