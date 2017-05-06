#! /bin/bash

_time=$(date +%Y%m%d-%H%M%S)
i=0
while [ $i -lt $2 ]; do
	date >> /tmp/bandwidth-info-bond0-${_time}.log
	/usr/sbin/iftop -i eth0 -B -t -s $1 >> /tmp/bandwidth-info-bond0-${_time}.log 2>&1
	let i=$i+1
done
