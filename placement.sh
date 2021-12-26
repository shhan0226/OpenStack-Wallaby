#!/bin/bash

read -p "What is openstack passwrd? : " STACK_PASSWD
echo "$STACK_PASSWD"


##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Placement Reg. Mariadb ..."
mysql -e "CREATE DATABASE placement;"
mysql -e "GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'localhost' IDENTIFIED BY '${STACK_PASSWD}';"
mysql -e "GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%' IDENTIFIED BY '${STACK_PASSWD}';"
mysql -e "FLUSH PRIVILEGES"


##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Openstack Placement ..."
. admin-openrc

openstack user create --domain default --password ${STACK_PASSWD} placement

openstack role add --project service --user placement admin

openstack service create --name placement --description "Placement API" placement

openstack endpoint create --region RegionOne placement public http://controller:8778
openstack endpoint create --region RegionOne placement internal http://controller:8778
openstack endpoint create --region RegionOne placement admin http://controller:8778


##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Install Placement ..."

apt install placement-api -y

crudini --set /etc/placement/placement.conf placement_database connection mysql+pymysql://placement:${STACK_PASSWD}@controller/placement

crudini --set /etc/placement/placement.conf api auth_strategy keystone

crudini --set /etc/placement/placement.conf keystone_authtoken auth_url http://controller:5000/v3   
crudini --set /etc/placement/placement.conf keystone_authtoken memcached_servers controller:11211
crudini --set /etc/placement/placement.conf keystone_authtoken auth_type password
crudini --set /etc/placement/placement.conf keystone_authtoken project_domain_name Default
crudini --set /etc/placement/placement.conf keystone_authtoken user_domain_name Default
crudini --set /etc/placement/placement.conf keystone_authtoken project_name service
crudini --set /etc/placement/placement.conf keystone_authtoken username placement
crudini --set /etc/placement/placement.conf keystone_authtoken password ${STACK_PASSWD}


##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "REG. DB  Placement ..."

su -s /bin/sh -c "placement-manage db sync" placement
su -s /bin/sh -c "placement-manage db sync" placement


##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Service restart"
service apache2 restart

. admin-openrc

placement-status upgrade check


##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "osc ... "
pip install osc-placement
openstack --os-placement-api-version 1.2 resource class list --sort-column name
openstack --os-placement-api-version 1.6 trait list --sort-column name
