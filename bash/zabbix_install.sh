#! /bin/bash
# From Matrix Zou for zabbix agent installation
# Maintainer    : jzou@freewheel.tv
# Version       : "0.1-20160621"
#
# $1 = ip address
#

if [ "$1" == "" ] ; then
        echo " "
        echo "missing arguments:"
        echo "------------------"
        echo " arg1 = ip address of zabbix agent to be installed "
        echo "------------------"
        echo " "
        exit
fi

# check dest reachable
ping -c1 $1 > /dev/null 2>&1
if [ $? != 0 ]; then
	echo " $1 unreachable "
	exit
fi

# check zabbix has been installed and running 
systemctl status zabbix-agent.service > /dev/null 2>&1
if [ $? == 0 ]; then 
	echo "zabbix is running now."
	exit
fi

rpm -qa | grep zabbix > /dev/null 2>&1
if [ $? == 0 ]; then
	echo "zabbix has been installed"
else	
	if [[ `uname -r` == *2.6.18* ]]; then
		scp ~/zabbix/zabbix-agent-3.0.0-2.el5.x86_64.rpm $1:/tmp/
		ssh $1 'yum localinstall -y /tmp/zabbix-agent-3.0.0-2.el5.x86_64.rpm --nogpgcheck'
	elif [[ `uname -r` == *2.6.32* ]]; then
		scp ~/zabbix/zabbix-agent-3.0.1-1.el6.x86_64.rpm $1:/tmp/
		ssh $1 'yum localinstall -y /tmp/zabbix-agent-3.0.1-1.el6.x86_64.rpm --nogpgcheck'
	else
		scp ~/zabbix/zabbix-agent-3.0.1-1.el7.x86_64.rpm $1:/tmp/
		ssh $1 'yum localinstall -y /tmp/zabbix-agent-3.0.1-1.el7.x86_64.rpm --nogpgcheck'
	fi
fi

# configuration file generate
scp ~/zabbix/zabbix_agentd.conf $1:/tmp/	
ssh $1 "echo "Hostname=`hostname -s`" >> /tmp/zabbix_agentd.conf"
ssh $1 "cp /etc/zabbix/zabbix_agentd.conf{,.orig}"
ssh $1 "cp /tmp/zabbix_agentd.conf /etc/zabbix/"

# start service
ssh $1 "uname -r > /tmp/uname"
ssh $1  "[[ `cat /tmp/uname` == *3.10.0* ]] && systemctl enable zabbix-agent.service"
ssh $1  "[[ `cat /tmp/uname` == *3.10.0* ]] && systemctl start zabbix-agent.service"
ssh $1  "[[ `cat /tmp/uname` == *2.6* ]] && chkconfig zabbix-agent on"
ssh $1  "[[ `cat /tmp/uname` == *2.6* ]] && /etc/init.d/zabbix-agent start"
