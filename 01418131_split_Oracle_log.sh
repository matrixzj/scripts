#!/bin/bash
#* for case 01418131 to split Oracle log in seperate files by Time

i=0

while read -r line
do
	echo $line | grep zzz 
	rt=$?
	if [ $rt -eq 0 ]; then
		let i=i+1;
		filename=`echo $line | awk '{print$5}'`
		touch f15rptp03_ps_15.03.13.0100.dat.result/$filename;
		echo $line >> f15rptp03_ps_15.03.13.0100.dat.result/$filename;
		echo $i;
	else
		echo $line >> f15rptp03_ps_15.03.13.0100.dat.result/$filename;	
        fi

done < $1

	
