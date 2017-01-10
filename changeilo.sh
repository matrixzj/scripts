#! /bin/bash

ipaddr=$1
network=$2
gw=$3

hponfig -w /tmp/ilo.xml
sed -e "/IP_ADDRESS VALUE/s/\(.* = "\).*\(".*\)/\1${ipaddr}\2/" -e "/GATEWAY_IP_ADDRESS VALUE/s/\(.* = "\).*\(".*\)/\1${gw}\2" -e "/SUBNET_MASK VALUE/s/\(.* = "\).*\(".*\)/\1${gw}\2"  /tmp/ilo.xml > //tmp/ilo1.xml

