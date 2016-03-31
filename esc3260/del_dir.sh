#!/bin/bash

# arg1=start, arg2=end, format: %s.%N  
function getTiming() {  
	start=$1  
	end=$2  
	 
	start_s=$(echo $start | cut -d '.' -f 1)  
	start_ns=$(echo $start | cut -d '.' -f 2)  
	end_s=$(echo $end | cut -d '.' -f 1)  
	end_ns=$(echo $end | cut -d '.' -f 2)  
# for debug..  
#    echo $start  
#    echo $end  
	time=$(( ( 10#$end_s - 10#$start_s ) * 1000 + ( 10#$end_ns / 1000000 - 10#$start_ns / 1000000 ) ))  
	echo "$time"  
} 

logfile=/tmp/deldir.log
echo > $logfile
missing_time=$(date +%s.%N)
duration=0

output="/tmp/nfs-deldir-$(date +"%Y-%m-%d-%H-%M-%S").pcap"
tcpdump="tcpdump -s0 -i eth0 host 192.168.10.240 -W 4 -C 256 -w $output -Z root"

# $tcpdump >/dev/null 2>&1 &
# pid=$!

while true; do {
	sleep 0.5;
	ls -al . | grep api_upload > /dev/null 2>&1
	rt=$?
	if [ $rt -eq 0 ]; then
	{	
		echo flos
		missing_time=$(date +%s.%N)
		printf "Existed: %s\n" "$(date +%Y-%m-%d\ %H:%M:%S.%N)" 
		printf "cmd: ls -al .\n" 
		ls -al . 
		printf "cmd: stat /mnt/nfs/test\n" 
		stat /mnt/nfs/test 
		printf "cmd: stat api_upload\n" 
		stat api_upload 
       		rm -rf api_upload; 
		printf "\n" 
		duration=0
	}
	else
	{
		echo matrix
		cur_time=$(date +%s.%N)
		duration=`getTiming $missing_time $cur_time`
		echo $duration
		if [ $duration -ge 80000 ]; then
			printf "Error: %s\t" "$(date +%Y-%m-%d\ %H:%M:%S.%N)" 
			echo 'ls -al .' 
			ls -al .  
			echo "issue has been reproduced at `hostname -s`" | mail -s 'Hurry Up' jzou@freewheel.tv;
			ssh 192.168.10.241 'killall tcpdump'
			ssh 192.168.10.241 'killall mk_dir.sh'
			kill $pid;
			break 1;
		fi
	}
	fi
} done

