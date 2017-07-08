#! /usr/bin/python

from sys import argv
import sys
import os
import time
import datetime
import shutil
import smtplib

sender = 'root@nycnfs202.fwmrm.net'
receivers = ['jzou@freewheel.tv']
message_header = """From: From root <root@nycnfs202.fwmrm.net>
To: To jzou <jzou@freewheel.tv>
Subject: file syncing was finished
"""

script, input_date = argv
source_base_dir = '/mnt/sftponlyha'
target_base_dir = '/mnt/sftponly_netapp'
customer_list_file = '/root/sftponly_migration/customer_list'
vendor_list_file = '/root/sftponly_migration/vendor_list'

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

rsync_format = "rsync -arq --delete-after --bwlimit=20000 %s %s"
#rsync_format = "rsync -arv --delete-after --bwlimit=20000 %s %s"

dict_sync = {	'ssh-keys' : '.ssh',
                '#companion-files' : 'companion-files',
                'audience_completed' : 'files/audience/ingest/completed',
                '#audience_pending' : 'files/audience/ingest/pending',
                '#audience_processing' : 'files/audience/ingest/processing',
                'bvi_completed' : 'files/bvi/completed',
                'bvi_failed' : 'files/bvi/failed',
                'bvi_log' : 'files/bvi/log',
                'bvi_long_tail' : 'files/bvi/long_tail',
                '#bvi_pending' : 'files/bvi/pending',
                '#bvi_processing' : 'files/bvi/processing',
                'fast_bvi_completed' : 'files/fast_bvi/completed',
                'fast_bvi_failed' : 'files/fast_bvi/failed',
                'fast_bvi_log' : 'files/fast_bvi/log',
                '#fast_bvi_pending' : 'files/fast_bvi/pending',
                '#fast_bvi_processing' : 'files/fast_bvi/processing',
		'#hylda' : 'files/hylda',
                'logs' : 'logs',
		'logs-hourly' : 'logs-hourly',
                'reports' : 'reports',
                'reports_audience' : 'reports/audience',
                'reports_customized' : 'reports/customized_rpt',
                'reports_mrma' : 'reports/mrma',
                '#v4logs' : 'v4logs'}

list_sync_dated = ['companion-files', 'audience_completed', 'bvi_completed', 'bvi_failed', 'bvi_log' , 'bvi_long_tail', 'fast_bvi_completed', 'fast_bvi_failed', 'fast_bvi_log', 'logs', 'reports', 'v4logs']
list_sync_nodated = ['ssh-keys', 'audience_pending', 'audience_processing', 'bvi_pending', 'bvi_processing', 'fast_bvi_pending', 'fast_bvi_processing', 'hylda', 'reports_audience', 'reports_customized', 'reports_mrma']
list_sync_hourly = ['logs-hourly']

def mirror_path(abs_path):
	source_path = abs_path
	rel_path = source_path.replace(source_base_dir + '/', '')
	target_path = os.path.join(target_base_dir, rel_path)
	if not os.path.isdir(target_path):
		source_path_info = os.stat(source_path)
		os.mkdir(target_path)
		os.chmod(target_path, int(oct(source_path_info.st_mode), 8))
		os.chown(target_path, source_path_info.st_uid, source_path_info.st_gid)
		print '%s\t%s\t%s\t%r' % (target_path, source_path_info.st_uid, source_path_info.st_gid, oct(source_path_info.st_mode))
	else:
		return 0

def sync_dated_path(path):
	migration_date_str = time.strftime('%Y-%m-%d', migration_date)
	source_path = os.path.join(source_base_dir, path, migration_date_str)
	target_path = os.path.join(target_base_dir, path, migration_date_str)
	if os.path.isdir(source_path):
		start_time = datetime.datetime.now()
		source_path += '/'
		target_path += '/'
		cmd = rsync_format % (source_path, target_path)
		print "\t" + bcolors.OKGREEN + source_path + " is syncing" + bcolors.ENDC
		os.system(cmd)
		end_time = datetime.datetime.now()
		duration = (end_time - start_time).seconds
		print "\tstarted: %s, ended: %s, duration(s): %s" % (start_time.strftime("%Y-%m-%d %H:%M:%S"), end_time.strftime("%Y-%m-%d %H:%M:%S"), duration)
        else:
                print "\t" + bcolors.FAIL + source_path + " is not existed" + bcolors.ENDC

def sync_nodated_path(path):
	source_path = os.path.join(source_base_dir, path)
	target_path = os.path.join(target_base_dir, path)
	if os.path.isdir(source_path):
		start_time = datetime.datetime.now()
		source_path += '/'
		target_path += '/'
		cmd = rsync_format % (source_path, target_path)
		print "\t" + bcolors.OKGREEN + source_path + " is syncing" + bcolors.ENDC
		os.system(cmd)
		end_time = datetime.datetime.now()
		duration = (end_time - start_time).seconds
		print "\tstarted: %s, ended: %s, duration(s): %s" % (start_time.strftime("%Y-%m-%d %H:%M:%S"), end_time.strftime("%Y-%m-%d %H:%M:%S"), duration)
        else:
                print "\t" + bcolors.FAIL + source_path + " is not existed" + bcolors.ENDC

def sync_hourly_path(path):
	migration_date_str = time.strftime('%Y%m%d', migration_date)
	source_top_path = os.path.join(source_base_dir, path)
	if not os.path.isdir(source_top_path):
		return 1
	sub_folder_list = os.listdir(source_top_path)
	for sub_folder in sub_folder_list:
		try:
			sub_folder_date = time.strptime(sub_folder[0:8], '%Y%m%d')
			if sub_folder_date == migration_date:
				start_time = datetime.datetime.now()
				source_path = os.path.join(source_top_path, sub_folder)
				target_path = os.path.join(target_base_dir, path, sub_folder)
				source_path += '/'
				target_path += '/'
				cmd = rsync_format % (source_path, target_path)
				print "\t" + bcolors.OKGREEN + source_path + " is syncing" + bcolors.ENDC
				os.system(cmd)
				end_time = datetime.datetime.now()
				duration = (end_time - start_time).seconds
				print "\tstarted: %s, ended: %s, duration(s): %s" % (start_time.strftime("%Y-%m-%d %H:%M:%S"), end_time.strftime("%Y-%m-%d %H:%M:%S"), duration)
		except ValueError:
			continue

def sync_folder(path):
	source_folder_path = os.path.join(source_base_dir, path)
	for dirname, subdirlist, filelist in os.walk(source_folder_path):
		 mirror_path(dirname)	

def process_vendor_folder(vendor_string):
	if not vendor_string.startswith('#'):
		print bcolors.HEADER + "Vendor: " + vendor.split(':')[0] + bcolors.ENDC
		if vendor_string.split(':')[2] == 'dated': 
			customer_list = os.listdir(os.path.join(source_base_dir, vendor_string.split(':')[0], vendor_string.split(':')[1]))
			for customer in customer_list:
				customer_path = os.path.join(source_base_dir, vendor_string.split(':')[0], vendor_string.split(':')[1], customer)
				rel_path = customer_path.replace(source_base_dir + '/', '')
				sync_dated_path(rel_path)
		elif vendor_string.split(':')[2] == 'nodated':
			customer_path = os.path.join(source_base_dir, vendor_string.split(':')[0], vendor_string.split(':')[1])
			rel_path = customer_path.replace(source_base_dir + '/', '')
			sync_nodated_path(rel_path)
		elif vendor_string.split(':')[2] == 'folder':
			customer_path = os.path.join(source_base_dir, vendor_string.split(':')[0], vendor_string.split(':')[1])
			rel_path = customer_path.replace(source_base_dir + '/', '')
			sync_folder(rel_path)
		elif vendor_string.split(':')[2] == 'hourly':
			customer_path = os.path.join(source_base_dir, vendor_string.split(':')[0], vendor_string.split(':')[1])
			rel_path = customer_path.replace(source_base_dir + '/', '')
			sync_hourly_path(rel_path)
		elif vendor_string.split(':')[2] == 'full':
			if vendor_string.split(':')[1] == '': 
				customer_path = os.path.join(source_base_dir, vendor_string.split(':')[0])
			else:
				customer_path = os.path.join(source_base_dir, vendor_string.split(':')[0], vendor_string.split(':')[1])
			rel_path = customer_path.replace(source_base_dir + '/', '')
			sync_nodated_path(rel_path)

def process_customer_folder(customer_string):
	print bcolors.HEADER + "Customer: " + customer_string + bcolors.ENDC
	for dict_key in sorted(dict_sync.keys()):
		if dict_key.startswith('#'):
			continue
		rel_path = customer_string + '/' + dict_sync[dict_key]
		if dict_key in list_sync_dated:
			sync_dated_path(rel_path)
		elif dict_key in list_sync_nodated: 
			sync_nodated_path(rel_path)
		elif dict_key in list_sync_hourly:
			sync_hourly_path(rel_path)

try: 
	migration_date = time.strptime(input_date, '%Y-%m-%d')
except ValueError:
	print bcolors.FAIL + 'input date is wrong!' + bcolors.ENDC
	sys.exit(1)

vendor_file = open(vendor_list_file, 'r')
vendor_line = vendor_file.read().splitlines()
vendor_file.close

for vendor in vendor_line:
	process_vendor_folder(vendor)

customer_file = open(customer_list_file, 'r')
customer_line = customer_file.read().splitlines()
customer_file.close

for customer in customer_line:
	process_customer_folder(customer)

migration_date_str = time.strftime('%Y%m%d', migration_date)
message = message_header + migration_date_str + ' files are finished at ' + datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
smtpObj = smtplib.SMTP('smtp.fwmrm.net', 25)
smtpObj.sendmail(sender, receivers, message)
smtpObj.quit()
print "Successfully sent email"
