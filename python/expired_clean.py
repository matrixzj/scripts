#! /usr/bin/python

from sys import argv
import os
import time
import datetime
import shutil

script, date_delta = argv
base_dir = '/mnt/sftponly_netapp'
customer_list_file = '/root/sftponly_folder_monitor/customer_list'
vendor_list_file = '/root/sftponly_folder_monitor/vendor_list'

target_date_arg = datetime.datetime.now() - datetime.timedelta(days = int(date_delta))
date_string =  target_date_arg.strftime('%Y-%m-%d')
target_date = time.strptime(date_string, '%Y-%m-%d')

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
		'logs-hourly' : 'logs-hourly',
                'reports' : 'reports',
                'reports_audience' : 'reports/audience',
                'reports_customized' : 'reports/customized_rpt',
                'reports_mrma' : 'reports/mrma',
                'v4logs' : 'v4logs'}

list_sync_dated = ['companion-files', 'audience_completed', 'bvi_completed', 'bvi_failed', 'bvi_log' , 'bvi_long_tail', 'fast_bvi_completed', 'fast_bvi_failed', 'fast_bvi_log', 'logs', 'reports', 'v4logs']
list_sync_nodated = ['reports_audience', 'reports_customized', 'reports_mrma']
list_sync_hourly = ['logs-hourly']

def process_dated_path(path):
	sub_folder_list = os.listdir(path)
	for sub_folder in sub_folder_list:
		try:
			sub_folder_date = time.strptime(sub_folder, '%Y-%m-%d')
			if sub_folder_date < target_date: 
				result_path = os.path.join(path, sub_folder)
				print bcolors.WARNING + "\tremoving: " + result_path + bcolors.ENDC
				shutil.rmtree(result_path)
		except ValueError:
			continue

def process_hourly_path(path):
	sub_folder_list = os.listdir(path)
	for sub_folder in sub_folder_list:
		try:
			sub_folder_date = time.strptime(sub_folder[0:8], '%Y%m%d')
			if sub_folder_date < target_date:
				result_path = os.path.join(path, sub_folder)
				print bcolors.WARNING + "\tremoving: " + result_path + bcolors.ENDC
				shutil.rmtree(result_path)
		except ValueError:
			continue

def process_file(file_path):
	file_mtime = time.strftime('%Y-%m-%d', time.gmtime(os.path.getmtime(file_path)))
	file_mdate = time.strptime(file_mtime, '%Y-%m-%d')
	if file_mdate < target_date:
		print bcolors.WARNING + "\tremoving: " + file_path + bcolors.ENDC
		os.remove(file_path)

def process_nodated_path(path):
	for dirname, dirnames, filenames in os.walk(path):
		for filename in filenames:
			process_file(os.path.join(dirname, filename))
	
def process_customer_folder(target_network):
	print bcolors.HEADER + "Network: " + target_network + bcolors.ENDC
	for index in dict_sync:
		abs_path = os.path.join(base_dir, target_network, dict_sync[index])
		if os.path.isdir(abs_path):
			if index in list_sync_dated:
				process_dated_path(abs_path)
			if index in list_sync_hourly:
				process_hourly_path(abs_path)
			if index in list_sync_nodated:
				process_nodated_path(abs_path)

def process_vendor_folder(vendor_string):
	print bcolors.HEADER + "Vendor: " + vendor.split(':')[0] + bcolors.ENDC
        vendor_sync_type = vendor.split(':')[1]
	if vendor_sync_type in {'full', 'reports_full', 'customized_reports', 'customized_rpt'}:
		if vendor_sync_type == 'vendor_sync_type':
			network_list = os.listdir(os.path.join(base_dir, vendor.split(':')[0]))
			for network in network_list:
				abs_path = os.path.join(base_dir, vendor.split(':')[0], network, 'customized_rpt')
				process_nodated_path(abs_path)
		else:
			abs_path = os.path.join(base_dir, vendor.split(':')[0])
			process_nodated_path(abs_path)
	if vendor_sync_type in {'logs', 'reports'}:
		network_list = os.listdir(os.path.join(base_dir, vendor.split(':')[0], vendor_sync_type))
		for network in network_list:
			abs_path = os.path.join(base_dir, vendor.split(':')[0], vendor_sync_type, network)
			process_dated_path(abs_path)
	if vendor_sync_type in {'logs-hourly'}:
		network_list = os.listdir(os.path.join(base_dir, vendor.split(':')[0]))
		for network in network_list:
			abs_path = os.path.join(base_dir, vendor.split(':')[0], network, 'logs-hourly')
			process_hourly_path(abs_path)

customer_file = open(customer_list_file, 'r')
customer_list = customer_file.read().splitlines()
customer_file.close()

for customer_id in customer_list:
	process_customer_folder(customer_id)

vendor_file = open(vendor_list_file, 'r')
vendor_line = vendor_file.read().splitlines()
vendor_file.close

for vendor in vendor_line:
	process_vendor_folder(vendor)
