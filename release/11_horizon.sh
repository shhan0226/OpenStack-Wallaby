#!/bin/bash

##################################
# Change root privileges.
##################################
IAMACCOUNT=$(whoami)
echo "${IAMACCOUNT}"

if [ "$IAMACCOUNT" = "root" ]; then
    echo "It's root account."
else
    echo "It's not a root account."
	exit 100
fi

##################################
# config /etc/hosts
##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "IP Setting ..."

ifconfig
read -p "Input Contorller IP: (ex.192.168.0.2) " SET_IP
read -p "What is openstack passwrd? : " STACK_PASSWD
echo "$STACK_PASSWD"
sync

##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Service Install ..."
apt install openstack-dashboard -y

cp /etc/openstack-dashboard/local_settings.py /etc/openstack-dashboard/local_settings.py.backup

sed -i "s/OPENSTACK_HOST = \"127.0.0.1\"/OPENSTACK_HOST = \"${SET_IP}\"/" /etc/openstack-dashboard/local_settings.py
sed -i "s/'LOCATION': '127.0.0.1:11211',/'LOCATION': '${SET_IP}:11211',/" /etc/openstack-dashboard/local_settings.py
sed -i 's/http:\/\/\%s\/identity\/v3/http:\/\/\%s:5000\/v3/' /etc/openstack-dashboard/local_settings.py
sed -i 's/#OPENSTACK_API_VERSIONS = {/OPENSTACK_API_VERSIONS = {/' /etc/openstack-dashboard/local_settings.py
sed -i 's/#    "identity": 3,/    "identity": 3,/' /etc/openstack-dashboard/local_settings.py
sed -i 's/#    "image": 2,/    "image": 2,/' /etc/openstack-dashboard/local_settings.py
sed -i 's/#    "volume": 3,/    "volume": 3,/' /etc/openstack-dashboard/local_settings.py
sed -i 's/#    "compute": 2,/    "compute": 2,\n}/' /etc/openstack-dashboard/local_settings.py
sed -i 's/#OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = False/OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = False/' /etc/openstack-dashboard/local_settings.py
sed -i 's/#OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = 'Default'/OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = 'Default'/' /etc/openstack-dashboard/local_settings.py
sed -i 's/TIME_ZONE = "UTC"/TIME_ZONE = "Asia\/Seoul"/' /etc/openstack-dashboard/local_settings.py
sync

##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Service reload ..."

#service apache2 reload
systemctl reload apache2.service