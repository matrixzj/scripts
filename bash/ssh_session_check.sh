#! /bin/bash -u

input_file='secure-ftp01.log.filtered'
tmpdir='/tmp/ssh_session'

target_time='Jun 23 07:24:51'
target_time_epoch=$(date -d "${target_time}" +%s)

#grep -n opened ${input_file} | sed -e 's/nycftp01 sshd\[//' -e 's/\]: pam_unix(sshd:session): session opened for user//' > ${input_file}.opened
#
#grep -n closed ${input_file} | sed -e 's/nycftp01 sshd\[//' -e 's/\]: pam_unix(sshd:session): session closed for user//' > ${input_file}.closed

open_file=${input_file}.opened
close_file=${input_file}.closed

line_number=1
while read -r line; do
#	echo $line_number
	pid=$(echo ${line} | awk '{print $4}')
	username=$(echo ${line} | awk '{print $5}')
	start_time=$(echo ${line} | sed -e 's/[0-9]*://'| awk 'BEGIN{OFS=" "} {print $1,$2,$3}')
	start_time_epoch=$(date -d "${start_time}" +%s)
	if [ ${start_time_epoch} -gt ${target_time_epoch} ]; then
		line_number=$(expr ${line_number} + 1)
		continue;
	fi
	awk -v p=${pid} '$4 == p {print}' ${close_file} | awk -v u=${username} '$5 == u{print}' > ${tmpdir}/${input_file}.closed.${pid}
	while read -r close_line; do
		end_time=$(echo ${close_line} | sed -e 's/[0-9]*://'| awk 'BEGIN{OFS=" "} {print $1,$2,$3}')
		end_time_epoch=$(date -d "${end_time}" +%s)
		if [ ${end_time_epoch} -ge ${start_time_epoch} -a ${end_time_epoch} -ge ${target_time_epoch} ];then 
			printf "%s\t%s\t%s\t%s\n" ${pid} ${username} $(date -d @"${start_time_epoch}" +"%F_%H:%M:%S") $(date -d @"${end_time_epoch}" +"%F_%H:%M:%S")
#			date -d @"${start_time_epoch}"
#			date -d @"${end_time_epoch}"
			break
		fi
	done < ${tmpdir}/${input_file}.closed.${pid}
	rm -f ${tmpdir}/${input_file}.closed.${pid}
	line_number=$(expr ${line_number} + 1)
done < ${open_file}
