#! /bin/bash
# From Matrix Zou for NFS/GlusterFS Benchmark (randwrite/randread)
# Maintainer    : jzou@freewheel.tv
# Version       : "0.2-20160405"
#
# $1 = IO performace Benchmark IO Pattern (randrw, randread, randwrite)
# $2 = Filesytems/mount point will be tested with
# $3 = Result Path
#
# crontab -u root -e
# 21 * * * * bash  /<path>/ioperf_iops_rand.sh randwrite /mnt/gluster /tmp/gluster-randwrite
#
#  04/05/2016 Matrix Zou	update file numbers tested with

if [ "$3" == "" ] ; then
        echo " "
        echo "missing arguments:"
        echo "------------------"
        echo " arg1 = IO performace Benchmark IO Pattern                e.g. randrw/randread/randwrite"
        echo " arg2 = Filesytems/mount point will be tested with        e.g. /mnt/gluster"
        echo " arg3 = Result Path                                       e.g. /tmp/gluster-randrw-bond (where to create result files)"
        echo " NOTE: If result path is existed, all data in it will be removed."
        echo "------------------"
        echo " "
        exit
fi

if [ ! -f randiops.fio ] ; then
        echo "Oops! fio profile file (randiops.fio) is not exited!"
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

hostname=`hostname -s`
mkdir ${target}/${hostname} > /dev/null 2>&1
for i in `seq 0 99`; do
        if [ ! -d ${target}/${hostname}/$i ]; then
                mkdir ${target}/${hostname}/$i
        fi
done

mkdir -p $base_dir/4K
#for threads in {32,64,100}; do
#{
#        mkdir -p $base_dir/4K/${threads}threads
#        nr=$((1000/$threads))
#        echo ===================================Test Start $(date +\%H\%d\%m)=================================== >> $base_dir/4K/${threads}threads/${test_type}
#        TYPE=${test_type} THREADS=$threads NRFILES=$nr FORMAT="${target}/${hostname}/\$jobnum/\$filenum" fio /root/randiops.fio >> $base_dir/4K/${threads}threads/${test_type}
#        echo ===================================Test Stop $(date +\%H\%d\%m)=================================== >> $base_dir/4K/${threads}threads/${test_type}
#}
#done

threads=32
mkdir -p $base_dir/4K/${threads}threads
nr=3
echo ===================================Test Start $(date +\%H\%d\%m)=================================== >> $base_dir/4K/${threads}threads/${test_type}
TYPE=${test_type} THREADS=$threads NRFILES=$nr FORMAT="${target}/${hostname}/\$jobnum/\$filenum" fio /root/randiops.fio >> $base_dir/4K/${threads}threads/${test_type}
echo ===================================Test Stop $(date +\%H\%d\%m)=================================== >> $base_dir/4K/${threads}threads/${test_type}


echo `hostname -s` done
