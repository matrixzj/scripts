#! /bin/bash

logfile=$1
user=$2
_temp=$(mktemp -d)
mkdir -p ${_temp}

egrep "session.*${user}" ${logfile} > ${_temp}/logfile
grep 'opened' ${_temp}/logfile | sed -e 's/.*\[\(.*\)\].*/\1/g' > ${_temp}/pid

cal_duration() {
	start=$2
	end=$1
	epoch_start=$(date --date "${start}" +%s)
	epoch_end=$(date --date "${end}" +%s)
	result=$((${epoch_end} - ${epoch_start}))
	echo $result
}

for pid in `cat ${_temp}/pid`; do 
       sed -ne "/\[${pid}\]/{:a;N;/\[${pid}\].*close.*/!{ba};N;p;q}" ${_temp}/logfile > ${_temp}/logfile_session
       start_time=$(egrep "\[${pid}\].*opened" ${_temp}/logfile_session | awk '{print $1,$2,$3}')
       end_time=$(egrep "\[${pid}\].*closed" ${_temp}/logfile_session | awk '{print $1,$2,$3}')
        duration=$(cal_duration "${end_time}" "${start_time}")
	if [ ${duration} -gt 10 ]; then 
	      	printf "session %s takes %s seconds, which started at %s\n" "${pid}" "${duration}" "${start_time}"
	fi
done

