#!/bin/bash

## tcpdump-fs
## Part of a series of tcpdump watch scripts for stopping tcpdump based on certain conditions.
## Maintainer: Kyle Squizzato - ksquizza@redhat.com

## This script captures a tcpdump until a Usage% value is either too high or too low.

## Fill in each of the variables in the SETUP section then invoke the script and wait for
## the issue to occur, the script will stop on it's own when the %Usage in df is either greater
## than or less than the $value specified, depending on the $delim chosen.

## -------- SETUP ---------

# File output location
output="/tmp/$(hostname)-$(date +"%Y-%m-%d-%H-%M-%S").pcap"

# Usage percentage value to check for
value=50

# Check interval
interval=15

# NFS mount to periodically check
nfsmount=/mnt/nfs

## ------- UNCOMMENT ONE VALUE BELOW ----------

# Uncomment the delim variable in this section if you wish to stop the script when the usage percentage is # GREATER THAN OR EQUAL TO the value above
#delim=ge

# Uncomment the delim variable in this section if you wish to stop the script when the usage percentage is # LESS THAN OR EQUAL TO the value above
#delim=le

## ------- UNCOMMENT ONE VALUE ABOVE ----------

# The only required parameter is the IP address of the NFS server
if [ $# -ne 1 ]; then
        echo "Usage : $0 <ip_of_nfs_server>"
        exit 1
fi
nfs_server=$1
if [[ $nfs_server =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo "Found valid IP address $nfs_server for NFS server"
	nfs_server_ip=$nfs_server
else
	# Attempt a host based lookup of the name
	which host >/dev/null 2>&1
	if [ $? -eq 0 ]; then
		nfs_server_ip=$(host $nfs_server | awk '/has address/ { print $NF }')
	fi
fi
if [ -z "$nfs_server_ip" ]; then
	echo "Could not validate $nfs_server as an IP or DNS name of NFS server"
	echo "Please enter a valid IP of NFS server"
	exit 1
fi

# Interface to gather tcpdump, derived based on the IP address of the NFS server
# NOTE: To prevent BZ 972396 we need to specify the interface by interface number
device=$(ip route get $nfs_server_ip | head -n1 | awk '{print $(NF-2)}')
interface=$(tcpdump -D | grep -e $device | colrm 3 | sed 's/\.//')

# The tcpdump command creates a circular buffer of -W X dump files -C YM in size (in MB).
# The default value is 4 files, 256M in size, it is recommended to modify the buffer values
# depending on the capture window needed.
tcpdump="tcpdump -s0 -ni $interface -W 4 -C 256 -w $output -Z root"

## -------- END SETUP ---------


$tcpdump &
pid=$!

while :; do
  percentage=$(df -h | grep $nfsmount | awk '{ print $5 }' | cut -d'%' -f1)
  if [ $percentage -$delim $value ]; then
        echo "$(date +%m-%d-%y@%H:%M): Detected deleted files on NFS export, killing rolling tcpdump now."
        kill $!
        break 1
  else
       	# Percentage not low enough, check again in 15 seconds
        sleep $interval
  fi
done

# Gzip the tcpdumps 
if [ -e /bin/gzip ]; then
        echo Gzipping $output
        gzip -f $output*
fi

# Tar everything together 
if [ -e /bin/tar ]; then 
        echo "Creating a tarball of $log and $output."
        tar czvf $output.tar.gz $output* 
fi

echo -e "\n "
echo -e '\E[1;31m'"Please upload" $output.tar.gz "to Red Hat for analysis."; tput sgr0
