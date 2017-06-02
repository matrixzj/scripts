#!/usr/bin/python

import os
from os.path import join, getmtime

basedir = '/mnt/sftponly'

all_subs = os.listdir(basedir)

for sub in all_subs:
	 if os.path.islink( os.path.join(basedir, sub) ):
		data_path = os.path.realpath( os.path.join(basedir, sub) )
		rel_data_path = os.path.relpath( data_path, basedir )
		print "%s\t\t%s" % ( rel_data_path, sub )
