#! /bin/bash
# From Matrix Zou for Repo Sync
# Maintainer    : jzou@freewheel.tv
# Version       : "0.2-20160418"
#
# $1 = channel name
# $2 = where all rpm packages will be downloaded in
# $3 = threads
#
#  04/18/2016 Matrix   enable multithreads

channel=$1
dst_dir=$2
threads=$3

if [ "$3" == "" ] ; then
        echo " "
        echo "missing arguments:"
        echo "------------------"
        echo " arg1 = channel name (it should be exactly the same with result of 'yum repolist')"
        echo " arg2 = path in which all rpm packages will be downloaded in "
        echo " arg3 = threads "
        echo " NOTE: If result path is existed, all data in it will be removed."
        echo "------------------"
        echo " "
        exit
fi

# disable yum plugin versionlock
sed -i '/^enabled/s/1/0/' /etc/yum/pluginconf.d/versionlock.conf
rm -f /tmp/${channel}.* 

# generate rpm list need to be downloaded
yum --showduplicates list available --disablerepo="*" --enablerepo=${channel} | tail -n +3 > /tmp/${channel}.raw-list
sed -i ':a;/'${channel}'$/!{N;s/\n//;ba}' /tmp/${channel}.raw-list
sed -i 's/[0-9]\{1,2\}://' /tmp/${channel}.raw-list
awk '{print$1}' /tmp/${channel}.raw-list | awk -F. 'BEGIN{OFS="."}{NF-=1;print}'| awk '{print NR,$0}' > /tmp/${channel}.name-list
awk  '{print NR,$1}' /tmp/${channel}.raw-list | awk -F. '{print NR,$NF}' > /tmp/${channel}.arch-list
awk  '{print NR,$2}' /tmp/${channel}.raw-list > /tmp/${channel}.version-list
join /tmp/${channel}.name-list /tmp/${channel}.version-list | awk '{printf("%s %s-%s\n",$1,$2,$3)}' > /tmp/${channel}.rpmlist_without_arch
join /tmp/${channel}.rpmlist_without_arch /tmp/${channel}.arch-list | awk '{printf("%s.%s\n",$2,$3)}' > /tmp/${channel}.rpmlist

# split rpmlist into $threads pieces
total_line=`cat /tmp/${channel}.rpmlist | wc -l`
round=$(($total_line/$threads))
i=0
while [ $i -le $round ]; do
        j=1
        while [ $j -le $threads ]; do
                line=$(($i*$threads+$j))
#               sed -n '/'$line'/p' /tmp/bak.${channel}.rpmlist
                awk -v l=$line 'NR==l{print$0}' /tmp/${channel}.rpmlist >> /tmp/${channel}.rpmlist.$j
                j=$(($j+1))
                if [ $line -ge $total_line ]; then
			break
                fi
        done
        i=$(($i+1))
done
unset i 
unset j
unset line

# download rpm
for i in `seq 1 $threads`; do 
	for line in `cat /tmp/${channel}.rpmlist.$i`; do yumdownloader --destdir=${dst_dir} $line; done > /tmp/${channel}.result.$i 2>&1 &
done
unset i

# waiting for downloader to be finished
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

# rm -f /tmp/${channel}.* 
sed -i '/^enabled/s/0/1/' /etc/yum/pluginconf.d/versionlock.conf
