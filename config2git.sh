#! /bin/bash
# From Matrix Zou for keep submit a directory to Git
# Maintainer    : Matrix Zou<jzou@freewheel.tv>
# Version       : "0.1-20160603"
#
# $1 = Directory
#
# crontab -u root -e
# 21 * * * *  /<path>/config2git.sh <Directroy>
#

die_msg() { echo ERROR: $@>&2; exit -1; }

[ ! -d $1 ] && die_msg Only accept a directory as parameter

cd $1 &>/dev/null || die_msg $0 cannot switch to working directory $1

git status | grep 'nothing to commit, working directory clean' > /dev/null 2>&1

rt=$?

project=`git remote -v | head -n1 | awk '{print $2}' | sed 's/.*\///' | sed 's/\.git//'`

if [ $rt != 0 ]; then
	find . -type f -mmin -60 -and -not -path "./.git/*"  > /tmp/${project}_modifiled_filelist
	for file in `cat /tmp/${project}_modifiled_filelist`; do git add $file; done
	echo "Modified files found at "  $(date +\%Y-\%m-%d\ \%H:\%M:\%S) > /tmp/${project}_commit_comment
	for list in `cat /tmp/${project}_modifiled_filelist`; do ls -l $list >> /tmp/${project}_commit_comment; done
	git commit -F /tmp/${project}_commit_comment
	git push || die $0 git commit failed
else
	exit 0 
fi
