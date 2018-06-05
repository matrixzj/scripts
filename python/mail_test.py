#! /usr/bin/python
import smtplib

sender = 'root@bjoops01.dev.test.net'
receivers = ['matrix.zj@gmail.com']

message = """From: From root <root@bjoops01.dev.test.net>
To: To jzou <matrix.zj@gmail.com>
Subject: SMTP e-mail test

This is a test e-mail message.
"""

smtpObj = smtplib.SMTP('smtp.dev.test.net')
smtpObj.sendmail(sender, receivers, message)         
smtpObj.quit()
print "Successfully sent email"
