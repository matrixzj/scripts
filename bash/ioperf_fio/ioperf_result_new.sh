#!/bin/bash

base=$1

result() {
	filename=$1
	threads=$2
# bw print $2, iops print $3
        cat $filename | egrep '^\s*write' | awk -F, '{print$2}' | awk -F= '{print$2}' | awk -v t=$threads 'BEGIN{test=0;sum=0}
	{if(test<t)
	{
	sum+=$1;
	test+=1;
	}}
	{if(test==t)
	{print sum;
	test=0;
	sum=0}}' | sort -rn | awk '{ if(NR>1 && NR<10)sum+=$1 fi} END {print sum/(NR-2)}'
}

for i in {1,2,4,8,16,32}; do
{
	bw=$(result "$1/${i}threads/randrw" $i)
        printf "%sthreads write bw: %.2f\n" $i $bw
} done

