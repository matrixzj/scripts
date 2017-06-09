#! /usr/bin/python

from sys import argv
import os
import time
import datetime
import shutil

script, date_delta = argv
base_dir = '/mnt/sftponly_netapp'
target_date_arg = datetime.datetime.now() - datetime.timedelta(days = int(date_delta))
date_string =  target_date_arg.strftime('%Y-%m-%d')
target_date = time.strptime(date_string, '%Y-%m-%d')
#print target_date_arg
#print type(target_date_arg)
#print target_date
#print type(target_date)
#target_date1 = target_date_arg.timetuple()
#print type(target_date1)

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

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

dict_sync_dated = ['companion-files', 'audience_completed', 'bvi_completed', 'bvi_failed', 'bvi_log' , 'bvi_long_tail', 'fast_bvi_completed', 'fast_bvi_failed', 'fast_bvi_log', 'logs', 'reports', 'v4logs']
dict_sync_nodated = ['reports_audience', 'reports_customized', 'reports_mrma']

network_id = 'adobe_upload'

def process_dated_folder(path):
	sub_folder_list = os.listdir(path)
	for sub_folder in sub_folder_list:
		try:
			sub_folder_date = time.strptime(sub_folder, '%Y-%m-%d')
			if sub_folder_date < target_date: 
				result_path = os.path.join(path, sub_folder)
				print bcolors.WARNING + "\tremoving: " + result_path + bcolors.ENDC
				shutil.rmtree(result_path)
		except ValueError:
			exit

def process_nodated_folder(path):
	sub_files_list = os.listdir(path)
	for file in sub_files_list:
		file_path = os.path.join(path, file)
		if os.path.isfile(file_path):
			file_mtime = time.strftime('%Y-%m-%d', time.gmtime(os.path.getmtime(file_path)))
			file_mdate = time.strptime(file_mtime, '%Y-%m-%d')
			if file_mdate < target_date:
				print file_path
	
def process_network(target_network):
	print bcolors.HEADER + "Network: " + target_network + bcolors.ENDC
	for index in dict_sync:
		abs_path = os.path.join(base_dir, network_id, dict_sync[index])
		if os.path.isdir(abs_path):
			if index in dict_sync_dated:
				process_dated_folder(abs_path)
			if index in dict_sync_nodated:
				process_nodated_folder(abs_path)

process_network(network_id)
