#! /bin/bash
# From Matrix Zou for NFS/GlusterFS Benchmark (iops)
# Maintainer	: jzou@freewheel.tv
# Version	: "0.1-20160314"
#
# $1 = IO performace Benchmark IO Pattern (randrw, randread, randwrite)
# $2 = Filesytems/mount point will be tested with
# $3 = Result Path
#
# crontab -u root -e
# 21 * * * * bash  /<path>/ioperf_iops.sh randrw /mnt/gluster /tmp/gluster-randrw-bond
#

if [ "$3" == "" ] ; then
	echo " "
	echo "missing arguments:"
	echo "------------------"
	echo " arg1 = IO performace Benchmark IO Pattern 		e.g. randrw/randread/randwrite"
	echo " arg2 = Filesytems/mount point will be tested with	e.g. /mnt/gluster"
	echo " arg3 = Result Path					e.g. /tmp/gluster-randrw-bond (where to create result files)"
	echo " NOTE: If result path is existed, all data in it will be removed."
	echo "------------------"
	echo " "
	exit
fi

if [ ! -f iops.fio ] ; then
	echo "Oops! iops.fio profile file is not exited!"
	exit
fi

if [ ! -x /usr/bin/fio ]; then 
        echo "can not locate fio, not installed?"
	echo "Installation Steps:"
	echo "rpm -ivh http://pkgs.repoforge.org/fio/fio-2.1.10-1.el7.rf.x86_64.rpm"
        exit
fi

test_type=$1
target=$2
result=$3

base_dir=$result/$test_type
rm -rf $base_dir
mkdir -p $base_dir
echo `hostname` > $base_dir/hostname

FORMAT=/mnt/nfsv3_bond/`hostname -s`.\$jobnum.\$filenum
echo $FORMAT

mkdir -p $base_dir/4K
for threads in {32,64,100}; do
{
	mkdir -p $base_dir/4K/${threads}threads
	i=0
#	while [ $i -lt 10 ]; do 
	echo ===================================Test Start $(date +\%H\%d\%m)=================================== >> $base_dir/4K/${threads}threads/${test_type}
	TYPE=${test_type} THREADS=$threads FORMAT="${target}/`hostname -s`.\$jobnum.\$filenum" fio /root/randiops.fio >> $base_dir/4K/${threads}threads/${test_type}
	echo ===================================Test Stop $(date +\%H\%d\%m)=================================== >> $base_dir/4K/${threads}threads/${test_type}
	let i=$i+1;
#	done
	unset i
}
done

