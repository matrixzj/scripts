#!/bin/bash

channel_file='/export/install/Cobbler/channel_list'
base_dir='/var/www/cobbler/repo_mirror'

os=$(hostnamectl | sed -ne '/Operating System:/{s/.*: //p}')

repo_config() {
	action=$1
	distro=$2
	if [ "${distro}" = "rhel" ]; then
		for repo in `awk -F'|' '{print $1}' ${channel_file} | grep -i 'centos'`; do 
			yum-config-manager --${action} "${repo}" >/dev/null 
		done
	elif [ "${distro}" = "centos" ]; then
		for repo in `awk -F'|' '{print $1}' ${channel_file} | grep -i '^rhel'`; do
                        yum-config-manager --${action} "${repo}" >/dev/null
                done
	fi
}
		 
if [ "${os}" = "Red Hat Enterprise Linux" ]; then 
	repo_config enable rhel
elif [ "${os}" = "CentOS Linux 7 (Core)" ]; then
	repo_config enable centos
else
	exit
fi

while read -r line
do 
	channel_name=$(echo ${line} | awk -F'|' '{print $1}')
	dir_name=$(echo ${line} | awk -F'|' '{print $2}')
	threads=$(echo ${line} | awk -F'|' '{print $3}')
	printf "Channel: %s\n" "${channel_name}"
	/export/install/Cobbler/repo_sync.sh -c ${channel_name} -d ${base_dir}/${dir_name} -t ${threads}
#	createrepo ${base_dir}/${dir_name}/ >/dev/null
done < ${channel_file}

if [ "${os}" = "Red Hat Enterprise Linux" ]; then 
	repo_config disable rhel
elif [ "${os}" = "CentOS Linux 7 (Core)" ]; then
	repo_config disable centos
fi
