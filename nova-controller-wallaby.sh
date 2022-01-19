#!/bin/bash

read -p "What is openstack passwrd? : " STACK_PASSWD
echo "$STACK_PASSWD"

sudo apt install net-tools -y
ifconfig
read -p "Input Contorller IP: (ex.192.168.0.2) " SET_IP


##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "NOVA Reg. Mariadb ..."
mysql -e "CREATE DATABASE nova_api;"
mysql -e "CREATE DATABASE nova;"
mysql -e "CREATE DATABASE nova_cell0;"

mysql -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY '${STACK_PASSWD}';"
mysql -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY '${STACK_PASSWD}';"

mysql -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '${STACK_PASSWD}';"
mysql -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY '${STACK_PASSWD}';"

mysql -e "GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' IDENTIFIED BY '${STACK_PASSWD}';"
mysql -e "GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY '${STACK_PASSWD}';"

mysql -e "FLUSH PRIVILEGES"


##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Openstack Nova ..."
. admin-openrc

openstack user create --domain default --password ${STACK_PASSWD} nova

openstack role add --project service --user nova admin

openstack service create --name nova --description "OpenStack Compute" compute

openstack endpoint create --region RegionOne compute public http://${SET_IP}:8774/v2.1
openstack endpoint create --region RegionOne compute internal http://${SET_IP}:8774/v2.1
openstack endpoint create --region RegionOne compute admin http://${SET_IP}:8774/v2.1


##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Install Nova Packages ..."

apt install nova-api nova-conductor nova-novncproxy nova-scheduler -y

crudini --set /etc/nova/nova.conf api_database connection mysql+pymysql://nova:${STACK_PASSWD}@${SET_IP}/nova_api

crudini --set /etc/nova/nova.conf database connection mysql+pymysql://nova:${STACK_PASSWD}@${SET_IP}/nova

crudini --set /etc/nova/nova.conf DEFAULT transport_url rabbit://openstack:${STACK_PASSWD}@${SET_IP}:5672/

crudini --set /etc/nova/nova.conf api auth_strategy keystone

crudini --set /etc/nova/nova.conf keystone_authtoken www_authenticate_uri http://${SET_IP}:5000/
crudini --set /etc/nova/nova.conf keystone_authtoken auth_url http://${SET_IP}:5000/
#crudini --set /etc/nova/nova.conf keystone_authtoken auth_url http://${SET_IP}:5000/v3
crudini --set /etc/nova/nova.conf keystone_authtoken memcached_servers ${SET_IP}:11211
crudini --set /etc/nova/nova.conf keystone_authtoken auth_type password
crudini --set /etc/nova/nova.conf keystone_authtoken project_domain_name Default
crudini --set /etc/nova/nova.conf keystone_authtoken user_domain_name Default
crudini --set /etc/nova/nova.conf keystone_authtoken project_name service
crudini --set /etc/nova/nova.conf keystone_authtoken username nova
crudini --set /etc/nova/nova.conf keystone_authtoken password ${STACK_PASSWD}

crudini --set /etc/nova/nova.conf DEFAULT my_ip ${SET_IP}

crudini --set /etc/nova/nova.conf vnc enabled true
crudini --set /etc/nova/nova.conf vnc server_listen \$my_ip
crudini --set /etc/nova/nova.conf vnc server_proxyclient_address \$my_ip

crudini --set /etc/nova/nova.conf glance api_servers http://${SET_IP}:9292

crudini --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp

crudini --set /etc/nova/nova.conf placement region_name RegionOne 
crudini --set /etc/nova/nova.conf placement project_domain_name Default
crudini --set /etc/nova/nova.conf placement project_name service
crudini --set /etc/nova/nova.conf placement auth_type password
crudini --set /etc/nova/nova.conf placement user_domain_name Default
crudini --set /etc/nova/nova.conf placement auth_url http://${SET_IP}:5000/v3
crudini --set /etc/nova/nova.conf placement username placement
crudini --set /etc/nova/nova.conf placement password ${STACK_PASSWD}

##
crudini --set /etc/nova/nova.conf use_neutron true
crudini --set /etc/nova/nova.conf firewall_driver nova.virt.firewall.NoopFirewallDriver


##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "DB REG."
su -s /bin/sh -c "nova-manage api_db sync" nova
sync
su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova
sync
su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova
sync
su -s /bin/sh -c "nova-manage db sync" nova
sync
su -s /bin/sh -c "nova-manage cell_v2 list_cells" nova
sync

##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "service restart"
service nova-api restart
#service nova-consoleauth restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart

