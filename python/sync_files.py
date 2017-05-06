#! /usr/bin/python

import datetime
import os
from sys import argv

origin_dir = '/mnt/sftponly/'
target_dir = '/mnt/sftponly_netapp'

script, network = argv

today = datetime.date.today()

reports_dir = os.path.join(network, 'reports', str(today))
print reports_dir

if os.path.isdir( os.path.join(origin_dir, reports_dir) ):
	print reports_dir
