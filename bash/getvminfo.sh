#!/bin/bash

virsh list | awk '{if(NR>2)print $2}' | grep -v ^$ > /tmp/vm_list

while read -r line; do 
	cpu=$(virsh dumpxml ${line} | awk 'BEGIN{FS=">"}/vcpu/{print$2}' | awk 'BEGIN{FS="<"}{print $1}')
	mem=$(virsh dumpxml ${line} | awk 'BEGIN{FS=">"}/currentMemory/{print$2}' | awk 'BEGIN{FS="<"}{print $1/1024/1024}')
	
	declare -a dev_list
	i=0
	for dev in $(virsh dumpxml ${line} | sed -ne '/^\s*<disk/{:a;N;/\s*<\/disk>/!{ba};p}' |  awk -F"'" '/target dev/{print $2}'); do
	dev_list[${i}]=${dev}
	i=$(expr $i + 1)
	done
	unset i
	
	declare -a dev_size
	dev_counter=${#dev_list[@]}	
	for (( i=0; i<${dev_counter}; i++ )); do
		dev_file=$(virsh dumpxml ${line} | sed -ne '/^\s*<disk/{:a;N;/\s*<\/disk>/!{ba};s/\n/\t/g;p}' | grep ${dev_list[$i]} | sed -e "s#.*source file='##" | sed -e "s#'.*##")
		dev_size[${i}]=$(qemu-img info ${dev_file} | awk '/virtual size/{print $3}')
	done
	unset i

	dev_size_string=' '
	for (( i=0; i<${dev_counter}; i++ )); do
		if [ $(expr $i + 1) -eq ${dev_counter} ]; then
			dev_size_string=$(printf "%s%s\n" ${dev_size_string} ${dev_size[$i]})
		else
			dev_size_string=$(printf "%s%s/\n" ${dev_size_string} ${dev_size[$i]})
		fi
	done
	printf "%s %s %s %s\n" ${line} ${cpu} ${mem} ${dev_size_string}
	unset dev_list
        unset dev_size
done < /tmp/vm_list
