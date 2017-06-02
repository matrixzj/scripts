#! /usr/bin/python
import smtplib

sender = 'root@bjoops01.dev.fwmrm.net'
receivers = ['jzou@freewheel.tv']

message = """From: From root <root@bjoops01.dev.fwmrm.net>
To: To jzou <jzou@freewheel.tv>
Subject: SMTP e-mail test

This is a test e-mail message.
"""

smtpObj = smtplib.SMTP('smtp.dev.fwmrm.net')
smtpObj.sendmail(sender, receivers, message)         
smtpObj.quit()
print "Successfully sent email"
