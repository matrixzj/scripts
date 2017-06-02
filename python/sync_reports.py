#! /usr/bin/python

import os
from sys import argv
import datetime
import sys
# from time import gmtime, strftime
import smtplib

script, p_date = argv

sender = 'root@nycnfs202.fwmrm.net'
receivers = ['jzou@freewheel.tv']

message_header = """From: From root <root@nycnfs202.fwmrm.net>
To: To jzou <jzou@freewheel.tv>
Subject: file syncing was finished
"""

smtpObj = smtplib.SMTP('smtp.fwmrm.net', 25)

origin_dir = '/mnt/sftponlyha'
target_dir = '/mnt/sftponly_netapp'


today = datetime.date.today()
# yesterday = datetime.date.fromordinal( today.toordinal() - 2 ).strftime("%F")
# yesterday = '2017-05-30'

dict_syncing = {'reports' : 'reports', 
		'logs' : 'logs',
		'bvi_archive' : 'files/bvi/archive', 
		'bvi_completed' : 'files/bvi/completed', 
		'bvi_failed' : 'files/bvi/failed',
		'bvi_log' : 'files/bvi/log',
		'bvi_long_tail' : 'files/bvi/long_tail',
		'fast_bvi_archive' : 'files/fast_bvi/archive', 
		'fast_bvi_completed' : 'files/fast_bvi/completed', 
		'fast_bvi_log' : 'files/fast_bvi/log',
		'fast_bvi_failed' : 'files/fast_bvi/failed',
		'audience_ingest_completed' : 'files/audience/ingest/completed',
		'customized_reports' : 'reports/customized_rpt', 
		'mrma_reports' : 'reports/mrma' }

def syncing_folders(type, path):
	origin_function_dir = os.path.join(origin_dir, network, path, p_date)
	target_function_dir = os.path.join(target_dir, network, path, p_date)
	if os.path.isdir( origin_function_dir ):
		start_time = datetime.datetime.now()
		if os.path.isdir( target_function_dir ):
		        origin_function_dir = origin_function_dir + '/'
		        target_function_dir = target_function_dir + '/'
		        cmd = "rsync -arq --delete-after --bwlimit=20000 %s %s" % (origin_function_dir, target_function_dir)
		        os.system( cmd )
			end_time = datetime.datetime.now()
			duration = (end_time - start_time).seconds
		        print "\t%s syncing was started at %s, ended at %s, taken %s seconds" % (type, start_time.strftime("%Y-%m-%d %H:%M:%S"), end_time.strftime("%Y-%m-%d %H:%M:%S"), duration)
			return 1
		else:
		        target_function_dir = os.path.join(target_dir, network, path)
		        cmd = "rsync -arq --delete-after --bwlimit=20000 %s %s" % (origin_function_dir, target_function_dir)
		        os.system( cmd )
			end_time = datetime.datetime.now()
			duration = (end_time - start_time).seconds
		        print "\t%s syncing was started at %s, ended at %s, taken %s seconds" % (type, start_time.strftime("%Y-%m-%d %H:%M:%S"), end_time.strftime("%Y-%m-%d %H:%M:%S"), duration)
			return 2
	else:
        	print "\tno " + type + " were found for " + p_date
		return 3

def syncing_non_dated_folders(type, path):
	origin_function_dir = os.path.join(origin_dir, network, path)
	target_function_dir = os.path.join(target_dir, network, path)
	if os.path.isdir( origin_function_dir ):
		start_time = datetime.datetime.now()
		if os.path.isdir( target_function_dir ):
		        origin_function_dir = origin_function_dir + '/'
		        target_function_dir = target_function_dir + '/'
		        cmd = "rsync -arq --delete-after --bwlimit=20000 %s %s" % (origin_function_dir, target_function_dir)
		        os.system( cmd )
			end_time = datetime.datetime.now()
			duration = (end_time - start_time).seconds
		        print "\t%s syncing was started at %s, ended at %s, taken %s seconds" % (type, start_time.strftime("%Y-%m-%d %H:%M:%S"), end_time.strftime("%Y-%m-%d %H:%M:%S"), duration)
			return 1
		else:
		        target_function_dir = os.path.join(target_dir, network, path)
		        cmd = "rsync -arq --delete-after --bwlimit=20000 %s %s" % (origin_function_dir, target_function_dir)
		        os.system( cmd )
			end_time = datetime.datetime.now()
			duration = (end_time - start_time).seconds
		        print "\t%s syncing was started at %s, ended at %s, taken %s seconds" % (type, start_time.strftime("%Y-%m-%d %H:%M:%S"), end_time.strftime("%Y-%m-%d %H:%M:%S"), duration)
			return 2
	else:
        	print "\tno " + type + " were found for " + p_date
		return 3

def process_network(p_network):
	print "Network: %s" % (p_network)
	for i in dict_syncing:
		if i in ['customized_reports', 'mrma_reports']:
			syncing_non_dated_folders(i, dict_syncing[i])
		else:
			syncing_folders(i, dict_syncing[i])

network_file = open('/root/network_list', 'r')
network_list = network_file.read().splitlines()
network_file.close()

for network in network_list:
	process_network(network) 

message = message_header + p_date + ' files are finished at ' + datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

smtpObj.sendmail(sender, receivers, message)
smtpObj.quit()
print "Successfully sent email"
