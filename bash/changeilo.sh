ipaddr=$1
netmask=$2
gw=$3

/usr/sbin/hponcfg -w /tmp/ilo.xml
sed -e "/IP_ADDRESS VALUE/s/\(.* = \"\).*\(\".*\)/\1${ipaddr}\2/" -e "/GATEWAY_IP_ADDRESS VALUE/s/\(.* = \"\).*\(\".*\)/\1${gw}\2/" -e "/SUBNET_MASK VALUE/s/\(.* = \"\).*\(\".*\)/\1${netmask}\2/"  /tmp/ilo.xml -e "/DHCP_ENABLE VALUE/s/\(.* = \"\).*\(\".*\)/\1N\2/"  /tmp/ilo.xml> /tmp/ilo1.xml

  <ADD_USER
    USER_NAME = "admin"
    USER_LOGIN = "admin"
    PASSWORD = "ILO-r00t">
    <ADMIN_PRIV value = "Y"/>
    <REMOTE_CONS_PRIV value = "Y"/>
    <RESET_SERVER_PRIV value = "Y"/>
    <VIRTUAL_MEDIA_PRIV value = "Y"/>
    <CONFIG_ILO_PRIV value = "Y"/>
  </ADD_USER>
  <ADD_USER
    USER_NAME = "fwadmin"
    USER_LOGIN = "fwadmin"
    PASSWORD = "ILO-r00t">
    <ADMIN_PRIV value = "Y"/>
    <REMOTE_CONS_PRIV value = "Y"/>
    <RESET_SERVER_PRIV value = "Y"/>
    <VIRTUAL_MEDIA_PRIV value = "Y"/>
    <CONFIG_ILO_PRIV value = "Y"/>
  </ADD_USER>
  </USER_INFO>
 </LOGIN>
</RIBCL>
