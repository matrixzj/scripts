#! /bin/bash

_temp=$(mktemp -d)
mkdir -p ${_temp}

network_name=$1
source_base_dir='/mnt/sftponly'
target_base_dir='/mnt/sftponly_netapp'

printf "Processing Network: %s\n" "${network_name}"
find ${source_base_dir}/${network_name} -mtime -1 -type d | cut -d "/" -f 4- > ${_temp}/${network_name}_folderlist
if [ $(cat ${_temp}/${network_name}_folderlist | wc -l) -ne 0 ]; then 
	find ${source_base_dir}/${network_name} -mtime -1 -type f | cut -d "/" -f 4-  > ${_temp}/${network_name}_filelist
else
        printf "\tNo files were generated recently in Network %s.\n" "${network_name}"
        rm -rf ${_temp}
        exit 0
fi

# make all folders
max_folder_level=$(awk -F'/'  '{print NF}' ${_temp}/${network_name}_folderlist | sort -ru | head -n1)
i=1
while [ ${i} -le ${max_folder_level} ]; do 
	cut -d "/" -f 1-${i} ${_temp}/${network_name}_folderlist | sort -ru > ${_temp}/${network_name}_level${i}_folder
	for j in $(cat ${_temp}/${network_name}_level${i}_folder); do 
		if [ -d "${source_base_dir}/${j}" ] && [ ! -d "${target_base_dir}/${j}" ]; then
			permission=$(stat -c "%a %u %g %n" ${source_base_dir}/${j} | awk '{print $1}')
			user=$(stat -c "%a %u %g %n" ${source_base_dir}/${j} | awk '{print $2}')
			group=$(stat -c "%a %u %g %n" ${source_base_dir}/${j} | awk '{print $3}')
			mkdir -p ${target_base_dir}/${j}
			chmod ${permission} ${target_base_dir}/${j}
			chown ${user} ${target_base_dir}/${j}
			chgrp ${group} ${target_base_dir}/${j}
		fi
	done
	let i=${i}+1
done

if [ $(cat ${_temp}/${network_name}_filelist | wc -l) -eq 0 ]; then
	printf "\tNo files were generated recently in Network %s.\n" "${network_name}"
        rm -rf ${_temp}
	exit 0
fi
			
# sync files
if [ -f ${_temp}/${network_name}_file_result ]; then
	rm -f ${_temp}/${network_name}_file_result
fi

while read -r line; do
	if [ -f "${source_base_dir}/${line}" ]; then
		rsync -arq --bwlimit=10000 "${source_base_dir}/${line}" "${target_base_dir}/${line}"
		echo $? >> ${_temp}/${network_name}_file_result
	else
		echo 1 >> ${_temp}/${network_name}_file_result
	fi
done < ${_temp}/${network_name}_filelist

orig_line_number=$(cat ${_temp}/${network_name}_filelist | wc -l)
copied_number=$(cat ${_temp}/${network_name}_file_result | grep '^0$' | wc -l)
file_notextied_number=$(cat ${_temp}/${network_name}_file_result | grep '^1$' | wc -l)
result_line_number=$(expr ${copied_number} + ${file_notextied_number})

if [ ${orig_line_number} -eq ${result_line_number} ]; then
	printf "\tNetwork %s has been done with %s files.\n" "${network_name}" "${result_line_number}"
	rm -rf ${_temp}
else
	printf "\tPlease check Network %s in %s.\n" "${network_name}" "${_temp}"
fi
