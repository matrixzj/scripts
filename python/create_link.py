#!/usr/bin/python

import os
from os.path import join, getmtime

basedir = '/home/jzou/tmp'
dest_base_dir = '/home/jzou/tmp1'

all_subs = os.listdir(basedir)

for sub in all_subs:
	 if os.path.islink( os.path.join(basedir, sub) ):
		data_path = os.path.realpath( os.path.join(basedir, sub) )
		rel_data_path = os.path.relpath( data_path, basedir )
		print "%s\t\t%s" % ( rel_data_path, sub )
		os.chdir(dest_base_dir)
		os.symlink( rel_data_path, sub )
