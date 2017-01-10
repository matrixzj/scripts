#! /bin/bash
# From Matrix Zou for Repo Sync
# Maintainer    : jzou@freewheel.tv
# Version       : "0.3-20170110"
#
#  04/18/2016 Matrix	enable multithreads
#  01/10/2017 Matrix 	function and download retry

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

function generate_rpmlist() {
	# disable yum plugin versionlock
	sudo sed -i '/^enabled/s/1/0/' /etc/yum/pluginconf.d/versionlock.conf 

	# generate rpm list need to be downloaded
	yum --showduplicates list available --disablerepo="*" --enablerepo=${channel} | tail -n +3 > ${_temp}/${channel}.raw-list
	sed -i ':a;/'${channel}'$/!{N;s/\n//;ba}' ${_temp}/${channel}.raw-list
	sed -i 's/[0-9]\{1,2\}://' ${_temp}/${channel}.raw-list
	awk '{print$1}' ${_temp}/${channel}.raw-list | awk -F. 'BEGIN{OFS="."}{NF-=1;print}'| awk '{print NR,$0}' > ${_temp}/${channel}.name-list
	awk  '{print NR,$1}' ${_temp}/${channel}.raw-list | awk -F. '{print NR,$NF}' > ${_temp}/${channel}.arch-list
	awk  '{print NR,$2}' ${_temp}/${channel}.raw-list > ${_temp}/${channel}.version-list
	join ${_temp}/${channel}.name-list ${_temp}/${channel}.version-list | awk '{printf("%s %s-%s\n",$1,$2,$3)}' > ${_temp}/${channel}.rpmlist_without_arch
	join ${_temp}/${channel}.rpmlist_without_arch ${_temp}/${channel}.arch-list | awk '{printf("%s.%s\n",$2,$3)}' > ${_temp}/${channel}.rpmlist
}

function split() {
	parts=$1
	# split rpmlist into ${parts}
	total_line=$(cat ${_temp}/${channel}.rpmlist | wc -l)
	round=$((${total_line}/${parts}))
	i=0
	while [ $i -le ${round} ]; do
	        j=1
	        while [ $j -le ${parts} ]; do
	                line=$(($i*${parts}+$j))
	                awk -v l=$line 'NR==l{print$0}' ${_temp}/${channel}.rpmlist >> ${_temp}/${channel}.rpmlist.$j
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
	unset parts
}

function download() {
	part=$1
	echo ${BASHPID} > ${_temp}/${channel}.rpmlist.${part}.pid
	for line in $(cat ${_temp}/${channel}.rpmlist.${part}); do yumdownloader --destdir=${dst_dir} ${line}; done > ${_temp}/${channel}.result.${part}
	unset line
	unset part
}

function check_download() {
	local part=$1
	local pid=$(cat ${_temp}/${channel}.rpmlist.${part}.pid)
	/bin/ps aux | grep ${pid} | grep -v grep > /dev/null 2>&1
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

# rm -f ${_temp}/${channel}.* 
# sed -i '/^enabled/s/0/1/' /etc/yum/pluginconf.d/versionlock.conf

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
generate_rpmlist
split ${threads}

for i in `seq 1 ${threads}`; do 
	echo ${i} >> ${_temp}/download_list 
done
unset i

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
	done
	unset finished

	for i in `seq 1 ${threads}`; do
        	check_result ${i}
	done
	unset i

	failed=$(grep 1 ${_temp}/part*.check_result | wc -l)
	grep 1 ${_temp}/part*.check_result | awk -F':' '{print $1}' | sed -e 's/.*part\(.*\).check_result/\1/'> ${_temp}/download_list
done

rm -rf ${_temp}
