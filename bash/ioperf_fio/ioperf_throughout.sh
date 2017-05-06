#! /bin/bash
# From Matrix Zou for NFS/GlusterFS Benchmark (throughout)
# Maintainer    : jzou@freewheel.tv
# Version       : "0.1-20160314"
#
# $1 = IO performace Benchmark IO Pattern (read/write)
# $2 = Filesytems/mount point will be tested with
# $3 = Result Path
#
# crontab -u root -e
# 21 * * * * bash  /<path>/ioperf_throughout.sh read /mnt/gluster /tmp/gluster-randrw-bond
#

if [ "$3" == "" ] ; then
        echo " "
        echo "missing arguments:"
        echo "------------------"
        echo " arg1 = IO performace Benchmark IO Pattern                e.g. read/write"
        echo " arg2 = Filesytems/mount point will be tested with        e.g. /mnt/gluster"
        echo " arg3 = Result Path                                       e.g. /tmp/gluster-randrw-bond (where to create result files)"
        echo " NOTE: If result path is existed, all data in it will be removed."
        echo "------------------"
        echo " "
        exit
fi

if [ ! -f throughout.fio ] ; then
        echo "Oops! throught.fio profile file is not exited!"
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

rm -rf $result
mkdir -p $result
echo `hostname` > $result/hostname

i=1
while [ $i -le 10 ]; do 
	echo ===================================Test$i Start $(date +\%Y-\%m-\%d\ %T)=================================== >> $result/$test_type
	TYPE=$test_type FILENAME="$target/test1-`hostname -s`:$target/test2-`hostname -s`" fio throughout.fio >> $result/$test_type
	echo ===================================Test$i Stop $(date +\%Y-\%m-\%d\ %T)=================================== >> $result/$test_type
	let i=$i+1;
done
