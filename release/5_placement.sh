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
echo "Placement Reg. Mariadb ..."
mysql -e "CREATE DATABASE placement;"
mysql -e "GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'localhost' IDENTIFIED BY '${STACK_PASSWD}';"
mysql -e "GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%' IDENTIFIED BY '${STACK_PASSWD}';"
mysql -e "FLUSH PRIVILEGES"
sync

##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Openstack Placement ..."
. admin-openrc

openstack user create --domain default --password ${STACK_PASSWD} placement
openstack role add --project service --user placement admin
openstack service create --name placement --description "Placement API" placement
openstack endpoint create --region RegionOne placement public http://${SET_IP}:8778
openstack endpoint create --region RegionOne placement internal http://${SET_IP}:8778
openstack endpoint create --region RegionOne placement admin http://${SET_IP}:8778
sync

##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Install Placement ..."

apt install placement-api -y
sync

crudini --set /etc/placement/placement.conf placement_database connection mysql+pymysql://placement:${STACK_PASSWD}@${SET_IP}/placement
crudini --set /etc/placement/placement.conf api auth_strategy keystone
crudini --set /etc/placement/placement.conf keystone_authtoken auth_url http://${SET_IP}:5000/v3   
crudini --set /etc/placement/placement.conf keystone_authtoken memcached_servers ${SET_IP}:11211
crudini --set /etc/placement/placement.conf keystone_authtoken auth_type password
crudini --set /etc/placement/placement.conf keystone_authtoken project_domain_name Default
crudini --set /etc/placement/placement.conf keystone_authtoken user_domain_name Default
crudini --set /etc/placement/placement.conf keystone_authtoken project_name service
crudini --set /etc/placement/placement.conf keystone_authtoken username placement
crudini --set /etc/placement/placement.conf keystone_authtoken password ${STACK_PASSWD}
sync

##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "REG. DB  Placement ..."
su -s /bin/sh -c "placement-manage db sync" placement
sync

##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Service restart"
service apache2 restart
sync

. admin-openrc
placement-status upgrade check

##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "osc ... "
. admin-openrc

pip3 install osc-placement
openstack --os-placement-api-version 1.2 resource class list --sort-column name
openstack --os-placement-api-version 1.6 trait list --sort-column name
sync