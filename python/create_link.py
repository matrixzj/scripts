#!/usr/bin/python

import os
from os.path import join, getmtime

basedir = '/mnt/sftponlyha'

all_sub = os.listdir(basedir)

for sublink in all_sub:
	 if os.path.islink(os.path.join(basedir, sublink)):
		realpath = os.path.realpath(os.path.join(basedir, sublink))
		origpath = os.path.relpath(realpath, basedir)
		print "%s   %s" % (sublink, realpath)
