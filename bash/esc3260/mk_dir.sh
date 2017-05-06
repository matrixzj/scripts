#!/bin/bash

logfile="/tmp/mkdir.log"
echo > $logfile

output="/tmp/nfs-mkdir-$(date +"%Y-%m-%d-%H-%M-%S").pcap"
tcpdump="tcpdump -s0 -i eth0 host 192.168.10.240 -W 4 -C 256 -w $output -Z root"

# $tcpdump >/dev/null 2>&1 &
# pid=$!

while true; do {
	sleep 1;
	printf "%s\t" "$(date +%Y-%m-%d\ %H:%M:%S.%N)" 
	printf "cmd: ls -al /mnt/nfs/test \n" 
	ls -al /mnt/nfs/test 
	mkdir api_upload 
	printf "cmd: stat /mnt/nfs/test\n" 
	stat /mnt/nfs/test 
	printf "cmd: stat api_upload\n" 
	stat api_upload 
	printf "\n" 
	if [ ! -d "api_upload" ]; then
		printf "Error: %s\t" "$(date +%Y-%m-%d\ %H:%M:%S.%N)" 
#		kill $pid
		exit 1
	fi
} done

