#! /usr/bin/python
import os
from sys import argv
from os.path import join, getmtime

script, network = argv

origin_dir = '/mnt/sftponly/'
target_dir = '/mnt/sftponly_netapp'

top_dir = os.path.join(origin_dir, network)

print top_dir
top_dir_info = os.stat(top_dir)

try:
	os.stat(os.path.join(target_dir, network))
except:
	os.mkdir(os.path.join(target_dir, network))
	os.chmod(os.path.join(target_dir, network), int(oct(top_dir_info.st_mode) ,8))
	os.chown(os.path.join(target_dir, network), top_dir_info.st_uid, top_dir_info.st_gid)

all_folders = {}
for root, dirs, files in os.walk(top_dir):
	folder_rel_path = os.path.relpath(root, origin_dir)
	if folder_rel_path != '.':
		folder_info = os.stat(root)
		all_folders[folder_rel_path] = folder_info

for folder in sorted(all_folders.keys()):
	try:	
		os.stat(os.path.join(target_dir, folder))
	except:
		print folder 
		os.mkdir(os.path.join(target_dir, folder))
		os.chmod(os.path.join(target_dir, folder), int(oct(all_folders[folder].st_mode) ,8))
		os.chown(os.path.join(target_dir, folder), all_folders[folder].st_uid, all_folders[folder].st_gid)

