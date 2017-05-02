#! /bin/bash
# From Matrix Zou for Repo Sync
# Maintainer    : jzou@freewheel.tv
# Version       : "0.4-20170416"
#
#  04/18/2016 Matrix	enable multithreads
#  01/10/2017 Matrix 	function and download retry
#  04/16/2017 Matrix 	verify files are existed
#

os=$(hostnamectl | sed -ne '/Operating System:/{s/.*: //p}')
if [ "${os}" = "Red Hat Enterprise Linux" ]; then
	cache_dir='/var/cache/yum/x86_64/7Server'
elif [ "${os}" = "CentOS Linux 7 (Core)" ]; then
	cache_dir='/var/cache/yum/x86_64/7'
else
        exit
fi

_temp=$(mktemp -d)
mkdir -p ${_temp}

function usage() {
        cat <<-END >&2
	------------------
	USAGE: repo_sync {-c channel} {-d destination_directory} {-t threads}
	                  -c channel name  		# must be exactly the same with result of 'yum repolist')
	                  -d destination directory	# path in which all rpm packages will be downloaded in
	                  -t threads			# threads
	------------------
END
        exit
}

function rpmlist_genenrator() {
        yum clean metadata --disablerepo='*' --enablerepo="${channel}" >/dev/null 2>&1
        yum makecache --disablerepo='*' --enablerepo="${channel}" >/dev/null 2>&1

        cache_file=$(ls ${cache_dir}/${channel}/*primary* | awk -F'/' '{print $NF}')
        cp ${cache_dir}/${channel}/${cache_file} ${_temp}/${cache_file}
        filename=$(ls ${_temp}/${cache_file} | awk -F'/' '{print $NF}' | awk -F'.' '{print $1}')
        filetype=$(ls ${_temp}/${cache_file} | awk -F'/' '{print $NF}' | awk -F'.' '{print $2}')
        compressiontype=$(ls ${_temp}/${cache_file} | awk -F'/' '{print $NF}' | awk -F'.' '{print $3}')

        # decompression file
        compression_type=$(file ${_temp}/${cache_file} | awk '{print $2}')
        if [ "${compression_type}" = "bzip2" ]; then
                bunzip2 -dc ${_temp}/${cache_file} > ${_temp}/${channel}.${filetype}
        elif [ "${compression_type}" = "XZ" ]; then
                unxz -dc ${_temp}/${cache_file} > ${_temp}/${channel}.${filetype}
        fi

        # generate rpmlist from sqlite database or xml file
        file_type=$(file ${_temp}/${channel}.${filetype} | awk '{print $2}')
        if [ "${file_type}" = "SQLite" ]; then
                sqlite3 ${_temp}/${channel}.sqlite "select location_href from packages" | awk -F'/' '{print $NF}' | sed -e 's/\.rpm//' | sort > ${_temp}/${channel}.rpmlist
        elif [ "${file_type}" = "XZ" ]; then
                unxz -dc ${_temp}/${cache_file}
        fi            
}

function generate_rpmlist() {
	# disable yum plugin versionlock
	sed -i '/^enabled/s/1/0/' /etc/yum/pluginconf.d/versionlock.conf 

	# generate rpm list need to be downloaded
	yum clean all >/dev/null 2>&1
	yum --showduplicates list available --disablerepo="*" --enablerepo=${channel} | sed -e '1,/^Available.*/d' > ${_temp}/${channel}.raw-list 2>/dev/null
	sed -i ':a;/'${channel}'$/!{N;s/\n//;ba}' ${_temp}/${channel}.raw-list
	sed -i 's/[0-9]\{1,2\}://' ${_temp}/${channel}.raw-list
	awk '{print$1}' ${_temp}/${channel}.raw-list | awk -F. 'BEGIN{OFS="."}{NF-=1;print}'| awk '{print NR,$0}' > ${_temp}/${channel}.name-list
	awk  '{print NR,$1}' ${_temp}/${channel}.raw-list | awk -F. '{print NR,$NF}' > ${_temp}/${channel}.arch-list
	awk  '{print NR,$2}' ${_temp}/${channel}.raw-list > ${_temp}/${channel}.version-list
	join ${_temp}/${channel}.name-list ${_temp}/${channel}.version-list | awk '{printf("%s %s-%s\n",$1,$2,$3)}' > ${_temp}/${channel}.rpmlist_without_arch
	join ${_temp}/${channel}.rpmlist_without_arch ${_temp}/${channel}.arch-list | awk '{printf("%s.%s\n",$2,$3)}' > ${_temp}/${channel}.rpmlist
}

function verify_file_existed() {
	rpmlist_file=${_temp}/${channel}.rpmlist
	for file in $(cat ${rpmlist_file}); do 
		stat ${dst_dir}/${file}.rpm > /dev/null 2>&1
		if [ $? -ne 0 ]; then
			echo ${file} >> ${_temp}/${channel}.rpmlist.final
		else
			size_file=$(/bin/ls -al ${dst_dir}/${file}.rpm 2>/dev/null | awk '{print $5}')
			if [ ${size_file} -eq 0 ]; then
				rm -f ${dst_dir}/${file}.rpm
				echo ${file} >> ${_temp}/${channel}.rpmlist.final
			fi
		fi
	done
}

function split() {
	# split rpmlist into ${parts}
	if [ ! -e ${_temp}/${channel}.rpmlist.final ]; then 
		echo 'no files need to be downloaded'
		rm -rf ${_temp}
		exit 1
	fi
		
	total_line=$(cat ${_temp}/${channel}.rpmlist.final | wc -l)
	printf "Channel: %s\t\trpms: %s\n" "${channel}" "${total_line}"
	if [ ${total_line} -lt ${threads} ]; then
		threads=${total_line}
	fi

	round=$((${total_line}/${threads}))
	i=0
	while [ $i -le ${round} ]; do
	        j=1
	        while [ $j -le ${threads} ]; do
	                line=$(($i*${threads}+$j))
	                awk -v l=$line 'NR==l{print$0}' ${_temp}/${channel}.rpmlist.final >> ${_temp}/${channel}.rpmlist.$j
	                j=$(($j+1))
	                if [ ${line} -ge ${total_line} ]; then
				break
	                fi
	        done
	        i=$(($i+1))
	done
	unset i 
	unset j
	unset line
}

function download() {
	part=$1
	echo ${BASHPID} > ${_temp}/${channel}.rpmlist.${part}.pid
	# once failed, reslt file need to checked
	for line in $(cat ${_temp}/${channel}.rpmlist.${part}); do yumdownloader --disablerepo="*" --enablerepo=${channel} --destdir=${dst_dir} ${line}; done > ${_temp}/${channel}.result.${part}
	unset line
	unset part
}

function check_download() {
	local part=$1
	local pid=$(cat ${_temp}/${channel}.rpmlist.${part}.pid)
	/bin/ps ax -o pid | egrep "^${pid}$" > /dev/null 2>&1
	local rt=$?
	if [ ${rt} -eq 0 ]; then
		echo 1 > ${_temp}/part${part}.download_result
	else 
		echo 0 > ${_temp}/part${part}.download_result
	fi
	unset rt
	unset pid
}

function check_result() {
	local part=$1
	local source_line=$(cat ${_temp}/${channel}.rpmlist.${part} | wc -l)
	local result_line=$(cat ${_temp}/${channel}.result.${part} | wc -l)
	if [ $source_line -eq $result_line ]; then
		echo 0 > ${_temp}/part${i}.check_result
	else
		echo 1 > ${_temp}/part${i}.check_result
	fi 
	unset part
}

function init() {
	if [ $# -lt 6 ]; then
		usage
	fi
	while getopts "c:d:t:h" arg
	do
	        case ${arg} in
	                c)
				channel=${OPTARG}
	                        ;;
	                d)
				dst_dir=${OPTARG}
	                        ;;
	                t)
				threads=${OPTARG}
	                        ;;
	                h|?)
				usage
	                        exit 1
	                        ;;
	        esac
	done
}

init $@
rpmlist_genenrator
# generate_rpmlist
verify_file_existed
split

for i in `seq 1 ${threads}`; do 
	echo ${i} >> ${_temp}/download_list 
done
unset i

if [ -f /etc/yum/pluginconf.d/versionlock.conf ]; then
	sed -i '/^enabled/s/1/0/' /etc/yum/pluginconf.d/versionlock.conf 
fi

failed=1
while [ ${failed} -gt 0 ]; do 
	for i in `cat ${_temp}/download_list`; do 
		download ${i} &
	done
	unset i

	finished=1
	while [ ${finished} -gt 0 ]; do
		for i in `seq 1 ${threads}`; do
		        check_download ${i}
		done
		unset i
		finished=$(cat ${_temp}/part*.download_result | grep 1 | wc -l)
		sleep 15
	done
	unset finished

	for i in `seq 1 ${threads}`; do
        	check_result ${i}
	done
	unset i

	failed=$(grep 1 ${_temp}/part*.check_result | wc -l)
	grep 1 ${_temp}/part*.check_result | awk -F':' '{print $1}' | sed -e 's/.*part\(.*\).check_result/\1/'> ${_temp}/download_list
done

if [ -f /etc/yum/pluginconf.d/versionlock.conf ]; then
	sed -i '/^enabled/s/0/1/' /etc/yum/pluginconf.d/versionlock.conf 
fi
createrepo ${dst_dir}/ >/dev/null
rm -rf ${_temp}
