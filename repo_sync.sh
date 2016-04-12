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

yum --showduplicates list available --disablerepo="*" --enablerepo=${channel} | tail -n +4 > /tmp/${channel}.raw-list

sed -i ':a;/'${channel}'$/!{N;s/\n//;ba}' /tmp/${channel}.raw-list
sed -i 's/[0-9]://' /tmp/${channel}.raw-list

awk -F. '{print NR,$1}' /tmp/${channel}.raw-list > /tmp/${channel}.name-list
awk  '{print NR,$1}' /tmp/${channel}.raw-list | awk -F. '{print NR,$2}' > /tmp/${channel}.arch-list
awk  '{print NR,$2}' /tmp/${channel}.raw-list > /tmp/${channel}.version-list

# join /tmp/${channel}.name-list /tmp/${channel}.version-list | awk '{printf("%s-%s\n",$2,$3)}' > /tmp/${channel}.rpmlist
join /tmp/${channel}.name-list /tmp/${channel}.version-list | awk '{printf("%s %s-%s\n",$1,$2,$3)}' > /tmp/${channel}.rpmlist_without_arch
join /tmp/${channel}.rpmlist_without_arch /tmp/${channel}.arch-list | awk '{printf("%s.%s\n",$2,$3)}' > /tmp/${channel}.rpmlist

for line in `cat /tmp/${channel}.rpmlist`; do yumdownloader --destdir=${dst_dir} $line; done

rm -f /tmp/${channel}.* 

unset ${channel}
unset ${dst_dir}
