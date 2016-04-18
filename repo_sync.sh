#! /bin/bash
# From Matrix Zou for Repo Sync
# Maintainer    : jzou@freewheel.tv
# Version       : "0.1-20160412"
#
# $1 = channel name
# $2 = where all rpm packages will be downloaded in
#

channel=$1
dst_dir=$2
threads=$3

sed -i '/^enabled/s/1/0/' /etc/yum/pluginconf.d/versionlock.conf
rm -f /tmp/${channel}.* 
yum --showduplicates list available --disablerepo="*" --enablerepo=${channel} | tail -n +3 > /tmp/${channel}.raw-list

sed -i ':a;/'${channel}'$/!{N;s/\n//;ba}' /tmp/${channel}.raw-list
sed -i 's/[0-9]\{1,2\}://' /tmp/${channel}.raw-list

awk '{print$1}' /tmp/${channel}.raw-list | awk -F. 'BEGIN{OFS="."}{NF-=1;print}'| awk '{print NR,$0}' > /tmp/${channel}.name-list
awk  '{print NR,$1}' /tmp/${channel}.raw-list | awk -F. '{print NR,$NF}' > /tmp/${channel}.arch-list
awk  '{print NR,$2}' /tmp/${channel}.raw-list > /tmp/${channel}.version-list

join /tmp/${channel}.name-list /tmp/${channel}.version-list | awk '{printf("%s %s-%s\n",$1,$2,$3)}' > /tmp/${channel}.rpmlist_without_arch
join /tmp/${channel}.rpmlist_without_arch /tmp/${channel}.arch-list | awk '{printf("%s.%s\n",$2,$3)}' > /tmp/${channel}.rpmlist

line=`cat /tmp/${channel}.rpmlist | wc -l`
each=$(($line/$threads))

i=1
while [ $i -le $threads ]; do
        from=$((each*($i-1)+1))
        end=$((each*$i))
        if [ $i != $threads ]; then
                sed -ne ''$from','$end'p' /tmp/${channel}.rpmlist > /tmp/${channel}.rpmlist.$i
        else
                sed -ne ''$from',$p' /tmp/${channel}.rpmlist > /tmp/${channel}.rpmlist.$i
        fi
	for line in `cat /tmp/${channel}.rpmlist.$i`; do yumdownloader --destdir=${dst_dir} $line; done > /tmp/${channel}.result.$i 2>&1 &
        i=$(($i+1))
done
unset i

sleep 5
/usr/bin/ps aux | grep yumdownload | grep -v grep > /dev/null 2>&1
rt=$?
while [ $rt -eq 0 ]; do
	sleep 5
	/usr/bin/ps aux | grep yumdownload | grep -v grep > /dev/null 2>&1
	rt=$?
done 

i=1
while [ $i -le $threads ]; do
	source_line=`cat /tmp/${channel}.rpmlist.$i | wc -l`
	result_line=`cat /tmp/${channel}.result.$i | wc -l`
	if [ $source_line -eq $result_line ]; then
		echo "part $i is ok"
	else
		echo "part $i need to be redownloaded"
	fi 
        i=$(($i+1))
done
unset i

rm -f /tmp/${channel}.* 
sed -i '/^enabled/s/0/1/' /etc/yum/pluginconf.d/versionlock.conf
