#! /usr/bin/python

import os
from sys import argv
import datetime
import sys
# from time import gmtime, strftime

origin_dir = '/mnt/sftponly/'
target_dir = '/mnt/sftponly_netapp'

script, network = argv

today = datetime.date.today()
yesterday = datetime.date.fromordinal( today.toordinal() - 5 ).strftime("%F")

dict_syncing = {'reports' : 'reports', 
		'logs' : 'logs',
		'bvi_archive' : 'files/bvi/archive', 
		'bvi_completed' : 'files/bvi/completed', 
		'bvi_logs' : 'files/bvi/logs',
		'bvi_long_tail' : 'files/bvi/long_tail',
		'audience_ingest_completed' : 'files/audience/ingest/completed' }

def syncing_folders(type, path):
	origin_function_dir = os.path.join(origin_dir, network, path, str(yesterday))
	target_function_dir = os.path.join(target_dir, network, path, str(yesterday))
	if os.path.isdir( origin_function_dir ):
		start_time = datetime.datetime.now()
		if os.path.isdir( target_function_dir ):
		        origin_function_dir = origin_function_dir + '/'
		        target_function_dir = target_function_dir + '/'
		        cmd = "rsync -arq --delete-after --bwlimit=10000 {0} {1}".format(origin_function_dir, target_function_dir)
		        os.system( cmd )
			end_time = datetime.datetime.now()
			duration = (end_time - start_time).seconds
		        print "\t%s syncing was started at %s, ended at %s, taken %s seconds" % (type, start_time.strftime("%Y-%m-%d %H:%M:%S"), end_time.strftime("%Y-%m-%d %H:%M:%S"), duration)
			return 1
		else:
		        target_function_dir = os.path.join(target_dir, network, path)
		        cmd = "rsync -arq --delete-after --bwlimit=10000 {0} {1}".format(origin_function_dir, target_function_dir)
		        os.system( cmd )
			end_time = datetime.datetime.now()
			duration = (end_time - start_time).seconds
		        print "\t%s syncing was started at %s, ended at %s, taken %s seconds" % (type, start_time.strftime("%Y-%m-%d %H:%M:%S"), end_time.strftime("%Y-%m-%d %H:%M:%S"), duration)
			return 2
	else:
        	print "\tno " + type + " were found for " + yesterday
		return 3

print "Network: %s" % (network)

for i in dict_syncing:
	syncing_folders(i, dict_syncing[i])

