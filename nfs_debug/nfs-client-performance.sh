#!/bin/bash
## NFS performance data capture script
## Maintainer: Kyle Squizzato - ksquizza@redhat.com

## Fill in each of the variables in the SETUP section then start the script
## to capture performance data.  Script captures NFS memory usage, CPU, local disk
## IOs, stack traces (not by default) and a rolling tcpdump.

## -- SETUP --

# Check for prerequisites
for c in strace tcpdump mountstats iostat nfsiostat tar
do
	which $c &> /dev/null
	if [ $? -eq 1 ]; then
		echo "Missing required command: $c"
		exit 1
	fi
done

# Case Number
if [ -z "$CASENUMBER" ]; then
    CASENUMBER=CASENUMBER
fi
casenumber=$CASENUMBER

# Interval to wait in seconds before captures
interval="5"

# Stack trace interval.  Note: Stack traces generate a lot of CPU activity and has been commented out by default
# str="300"

# The only required parameter is the IP address of the NFS server
if [ $# -lt 1 ]; then
        echo "Usage : $0 <ip_of_nfs_server> [capture-seconds | NFS_CLIENT_PERFORMANCE_CMD]"
        echo "NOTE: For indefinite capture-seconds, enter -1 and this script will prompt to stop the data capture"
        echo "NOTE: The environment variable NFS_CLIENT_PERFORMANCE_CMD may also be defined, and the script starts/stops the data around this command runtime"
        exit 1
fi

nfs_server=$1
if [[ $nfs_server =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo "Found valid IP address $nfs_server for NFS server"
	nfs_server_ip=$nfs_server
else
	# Attempt a host based lookup of the name
	which host >/dev/null 2>&1
	if [ $? -eq 0 ]; then
		nfs_server_ip=$(host $nfs_server | awk '/has address/ { print $NF }')
	fi
fi
if [ -z "$nfs_server_ip" ]; then
	echo "Could not validate $nfs_server as an IP or DNS name of NFS server"
	echo "Please enter a valid IP of NFS server"
	exit 1
fi

# Capture time in seconds to capture all data.
if [ $# -eq 2 ]; then
	capture=$2
else
	capture=600
fi

# Interface to gather tcpdump, derived based on the IP address of the NFS server
# NOTE: To prevent BZ 972396 we need to specify the interface by interface number
device=$(ip route get $nfs_server_ip | head -n1 | awk '{print $(NF-2)}')
interface=$(tcpdump -D | grep -e $device | colrm 3 | sed 's/\.//')

## TCPDUMP Specific Options

# The tcpdump command creates a circular buffer of -W X dump files -C YM in size (in MB).
# The default value is 4 files, 256M in size, it is recommended to modify the buffer values
# depending on the capture window needed.
tcpdump="tcpdump -s 512 -i $interface host $nfs_server -W 4 -C 256 -w /tmp/performance.pcap -Z root"

## -- END SETUP --

# Capture data for NFS performance problems

# Copy the raw mountstats file so we can manipulate later
cp /proc/self/mountstats /tmp/mountstats.before.raw.out
# Run mountstats on each NFS mount point
awk '$2 !~ /\/proc\/fs\/nfsd/ && $3 ~ /nfs/ { print $2 }' /proc/mounts | while read nfsmounts; do date >> /tmp/mountstats.out ; echo "NFS Mount: $nfsmounts" >> /tmp/mountstats.out; mountstats --rpc $nfsmounts >> /tmp/mountstats.out; mountstats --nfs $nfsmounts >> /tmp/mountstats.before.out; done

$tcpdump &
nfsiostat $interval > /tmp/nfsiostat.out &
iostat -xt $interval > /tmp/iostat.out &
iostat -ct $interval > /tmp/nfs_cpu.out &
#(while true; do echo "t" > /proc/sysrq-trigger; sleep $str; done) &
(while true; do date >> /tmp/nfs_meminfo.out; cat /proc/meminfo | egrep "(Dirty|Writeback|NFS_Unstable):" >> /tmp/nfs_meminfo.out; sleep $interval; done) &

# Wait a small period of time to make sure the tcpdump and everything starts
sleep $interval

# Now if a command is specified in NFS_CLIENT_PERFORMANCE_CMD, run it under strace
if [ ! -z "$NFS_CLIENT_PERFORMANCE_CMD" ]; then
	echo "Running the following command under strace: $NFS_CLIENT_PERFORMANCE_CMD"
	strace -v -f -r -tt -T -o /tmp/strace.out $NFS_CLIENT_PERFORMANCE_CMD
# Wait either for a time in seconds, or for a keypress
elif [ $capture -gt 0 ]; then
	echo "Sleeping for $capture seconds"
	sleep $capture
else
	read -p "Press <Enter> to stop the data capture..."
fi

kill -9 $(jobs -p) > /dev/null 2>&1

# Copy the raw mountstats file so we can manipulate later
cp /proc/self/mountstats /tmp/mountstats.after.raw.out

# Run mountstats on each NFS mount point
awk '$2 !~ /\/proc\/fs\/nfsd/ && $3 ~ /nfs/ { print $2 }' /proc/mounts | while read nfsmounts; do date >> /tmp/mountstats.out ; echo "NFS Mount: $nfsmounts" >> /tmp/mountstats.out; mountstats --rpc $nfsmounts >> /tmp/mountstats.out; mountstats --nfs $nfsmounts >> /tmp/mountstats.after.out; done

# Tar up the resulting data set
sleep 10
tar czvf /tmp/$casenumber-$(hostname)-$(date +"%Y-%m-%d-%H-%M-%S").tar.gz /tmp/*.out /tmp/performance.pcap* /var/log/messages

echo -e 'DONE: Compressed statistics data can be found in' /tmp/$casenumber.tar.gz
