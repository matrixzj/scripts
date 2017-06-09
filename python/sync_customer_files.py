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

origin_dir = '/mnt/sftponlyha'
target_dir = '/mnt/sftponly_netapp'
customer_list_file = '/root/customer_list'

today = datetime.date.today()

dict_sync = {	'ssh-keys' : '.ssh',
		'companion-files' : 'companion-files',
		'audience_completed' : 'files/audience/ingest/completed',
		'bvi_completed' : 'files/bvi/completed',
		'bvi_failed' : 'files/bvi/failed',
		'bvi_log' : 'files/bvi/log',
		'bvi_long_tail' : 'files/bvi/long_tail',
		'fast_bvi_completed' : 'files/fast_bvi/completed', 
		'fast_bvi_failed' : 'files/fast_bvi/failed',
		'fast_bvi_log' : 'files/fast_bvi/log',
		'logs' : 'logs',
		'reports' : 'reports', 
		'reports_audience' : 'reports/audience',
		'reports_customized' : 'reports/customized_rpt',
		'reports_mrma' : 'reports/mrma',
		'v4logs' : 'v4logs'}

dict_not_sync = {	'audience_failed' : 'files/audience/ingest/failed',
			'bvi_archive' : 'files/bvi/archive',
			'fast_bvi_archive' : 'files/fast_bvi/archive', 
			'hylda' : 'files/hylda'}

dict_final_sync = {	'audience_pending' : 'files/audience/ingest/pending',
			'audience_processing' : 'files/audience/ingest/processing',
			'bvi_pending' : 'files/bvi/pending', 
			'bvi_processing' : 'files/bvi/processing',
			'fast_bvi_pending' : 'files/fast_bvi/pending',
			'fast_bvi_processing' : 'files/fast_bvi/processing'}

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

def mirror_path(path):
        origin_path_info = os.stat(os.path.join(origin_dir, path))
        os.mkdir(os.path.join(target_dir, path))
        os.chmod(os.path.join(target_dir, path), int(oct(origin_path_info.st_mode) ,8))
        os.chown(os.path.join(target_dir, path), origin_path_info.st_uid, origin_path_info.st_gid)

def get_relative_path(path):
        path_list = path.split('/')
        for i in range(3, len(path_list)):
                if i == 3:
                        relative_path = path_list[i]
                else:
                        relative_path = relative_path + '/' + path_list[i]
        return relative_path

def sync_folder(path, type):
        start_time = datetime.datetime.now()
        source_path = os.path.join(origin_dir, path)
        target_path = os.path.join(target_dir, path)
        if os.path.isdir(source_path):
                source_path += '/'
                target_path += '/'
                cmd = "rsync -arq --delete-after --bwlimit=20000 %s %s" % (source_path, target_path)
                os.system(cmd)
                end_time = datetime.datetime.now()
                duration = (end_time - start_time).seconds
                print "\t%s syncing was started at %s, ended at %s, taken %s seconds" % (type, start_time.strftime("%Y-%m-%d %H:%M:%S"), end_time.strftime("%Y-%m-%d %H:%M:%S"), duration)
        else:
                print "\t" + bcolors.FAIL + "no " + type + " were found for " + p_date + bcolors.ENDC

def sync_date_folders(path, type):
	source_abs_path = os.path.join(origin_dir, network, path, p_date)
	rel_path = get_relative_path(source_abs_path)
	sync_folder(rel_path, type)

def sync_non_dated_folders(path, type):
	source_abs_path = os.path.join(origin_dir, network, path)
	rel_path = get_relative_path(source_abs_path)
	sync_folder(rel_path, type)

def process_network(p_network):
	print bcolors.OKBLUE + "Network: " + p_network + bcolors.ENDC
	for i in dict_syncing:
		if i in ['customized_reports', 'mrma_reports']:
			sync_non_dated_folders(dict_syncing[i], i)
		else:
			sync_date_folders(dict_syncing[i], i)

network_file = open(customer_list_file, 'r')
network_list = network_file.read().splitlines()
network_file.close()

for network in network_list:
	process_network(network) 

message = message_header + p_date + ' files are finished at ' + datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
smtpObj = smtplib.SMTP('smtp.fwmrm.net', 25)
smtpObj.sendmail(sender, receivers, message)
smtpObj.quit()
print "Successfully sent email"
