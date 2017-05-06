#! /bin/bash

bs=$1

for t in {1,2,4,8,16,32}; do
        echo $t threads
        for i in `seq -w 1 10`; do cat client$i/${bs}K/${t}threads/randrw | egrep 'read|write' ; done | wc -l
        for i in `seq -w 1 10`; do cat client$i/${bs}K/${t}threads/randrw | egrep 'read|write' | grep 'KB/s'; done | wc -l
done
