#! /usr/bin/python
import time
import os
import sys

def startProgress(title):
    global progress_x
    progress_x = 0
    sys.stdout.write(title + ": [" + "-"*40 + "]" + chr(8)*41 + str(progress_x))
    sys.stdout.flush()

def progress():
    global progress_x
    global target_dir_size 
    target_dir_size = get_size(os.path.join(target_base_dir, subfolder))
    x = int((float(target_dir_size) / source_dir_size) * 40)
    sys.stdout.write("#" * (x - progress_x) + str(x))
    sys.stdout.flush()
    progress_x = x

def endProgress():
    sys.stdout.write("#" * (40 - progress_x) + "]\n")
    sys.stdout.flush()

def get_size(start_path):
    total_size = 0
    for dirpath, dirnames, filenames in os.walk(start_path):
        for f in filenames:
            fp = os.path.join(dirpath, f)
            total_size += os.path.getsize(fp)
    return total_size

source_base_dir = '/home/jzou/os_provision/'
target_base_dir = '/tmp/'
subfolder = 'kvm_template'

global source_dir_size 
source_dir_size = get_size(os.path.join(source_base_dir, subfolder))
global target_dir_size
target_dir_size = 0

startProgress('Matrix')
while target_dir_size < source_dir_size:
	progress()
	time.sleep(10)
endProgress()
