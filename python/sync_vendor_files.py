#! /usr/bin/python

import os
from sys import argv
import datetime
import sys
import smtplib

script, p_date = argv

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

origin_dir = '/mnt/sftponlyha'
target_dir = '/mnt/sftponly_netapp'
vendor_list_file = '/root/vendor_list'

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
		print cmd
		end_time = datetime.datetime.now()
		duration = (end_time - start_time).seconds
		print "\t%s syncing was started at %s, ended at %s, taken %s seconds" % (type, start_time.strftime("%Y-%m-%d %H:%M:%S"), end_time.strftime("%Y-%m-%d %H:%M:%S"), duration)
	else:
        	print "\t" + bcolors.FAIL + "no " + type + " were found for " + p_date + bcolors.ENDC

def sync_reports_logs(network, type):
	top_network_path = os.path.join(origin_dir, network, type)
	network_list = os.listdir(top_network_path)
	for sub_network in network_list:
		target_network_path = os.path.join(target_dir, network, type, sub_network)
		if not os.path.isdir(target_network_path):
			mirror_path(get_relative_path(target_network_path))
		rel_path = get_relative_path(os.path.join(top_network_path, sub_network, p_date))
		print bcolors.OKBLUE + "\t" + rel_path + bcolors.ENDC
		sync_folder(rel_path, type)

def sync_log_hourly(top_network, type):
	top_network_path = os.path.join(origin_dir, top_network)
        network_list = os.listdir(top_network_path)
	for network in network_list:
		source_network_dir = os.path.join(top_network_path, network, type)
		date_list = p_date.split('-')
		date_string = ''.join(date_list)
		date_list = []
		for hour in range(0, 24):
			date_list.append(date_string + str(hour).zfill(2) + '0000')
		path_list = []
		for date_stamp in date_list:
			sync_folder(get_relative_path(os.path.join(source_network_dir, date_stamp)), type)

def sync_customized_rpt(top_network, type):
	top_network_path = os.path.join(origin_dir, top_network)
	network_list = os.listdir(top_network_path)
	for sub_network in network_list:
		target_network_path = os.path.join(target_dir, sub_network)
		if not os.path.isdir(target_network_path):
			mirror_path(get_relative_path(target_network_path))
		sync_folder(get_relative_path(os.path.join(top_network_path, sub_network, type)), type)

def sync_reports_full(network, type):
	top_network_path = os.path.join(origin_dir, network, 'reports')
	network_list = os.listdir(top_network_path)
	for sub_network in network_list:
		sync_folder(get_relative_path(os.path.join(top_network_path, sub_network)), type)
	
def sync_customized_reports(network, type):
	top_network_path = os.path.join(origin_dir, network, 'reports')
	network_list = os.listdir(top_network_path)
	for sub_network in network_list:
		target_network_path = os.path.join(target_dir, network, 'reports', sub_network)
		if not os.path.isdir(target_network_path):
			mirror_path(get_relative_path(target_network_path))
		sync_folder(get_relative_path(os.path.join(top_network_path, sub_network, 'customized_rpt')), type)


vendor_file = open(vendor_list_file, 'r')
vendor_line = vendor_file.read().splitlines()
vendor_file.close
for line in vendor_line:
	type = line.split(':')[1] 
	print bcolors.OKBLUE + line.split(':')[0] + ' (' + type + ')'+ bcolors.ENDC
#	if type in ['reports', 'logs']:
#		sync_reports_logs(line.split(':')[0], type)
#	if type == 'logs-hourly':
#		sync_log_hourly(line.split(':')[0], type)
#	if type == 'full':
#		sync_folder(line.split(':')[0], type)
#	if type == 'customized_rpt':
#		sync_customized_rpt(line.split(':')[0], type)
#	if type == 'reports_full':
#		sync_reports_full(line.split(':')[0], type)
	if type == 'customized_reports':
		sync_customized_reports(line.split(':')[0], type)
