#!/bin/bash

read -p "What is openstack passwrd? : " STACK_PASSWD
echo "$STACK_PASSWD"

apt install net-tools -y


##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "IP Setting ..."
ifconfig
read -p "Input Contorller IP: (ex.192.168.0.2) " CON_IP
read -p "Input Compute IP: " SET_IP


##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Install KVM ..."
apt-get install qemu-kvm -y
apt-get install libvirt-bin -y
apt-get install virtinst -y
apt-get install bridge-utils -y
apt-get install cpu-checker -y
apt-get install virt-manager -y 
apt-get install qemu-efi -y
#apt-get install ubuntu-vm-builder -y
#apt-get install virt-manager -y

sync
sudo adduser $USER kvm
#sudo adduser $(id -un) libvirt
#sudo adduser $(id -un) libvirtd

sync
kvm-ok


##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Install NOVA-Compute ..."
apt install nova-compute -y


##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "NOVA Conf. ..."

crudini --set /etc/nova/nova.conf DEFAULT transport_url rabbit://openstack:stack@${CON_IP}
crudini --set /etc/nova/nova.conf DEFAULT my_ip ${SET_IP}
#crudini --set /etc/nova/nova.conf DEFAULT use_neutron true
#crudini --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver

crudini --set /etc/nova/nova.conf api auth_strategy keystone

crudini --set /etc/nova/nova.conf keystone_authtoken www_authenticate_uri http://${CON_IP}:5000/
#crudini --set /etc/nova/nova.conf keystone_authtoken auth_url http://controller:5000/v3
crudini --set /etc/nova/nova.conf keystone_authtoken auth_url http://${CON_IP}:5000/
crudini --set /etc/nova/nova.conf keystone_authtoken memcached_servers ${CON_IP}:11211
crudini --set /etc/nova/nova.conf keystone_authtoken auth_type password
crudini --set /etc/nova/nova.conf keystone_authtoken project_domain_name Default
crudini --set /etc/nova/nova.conf keystone_authtoken user_domain_name Default
crudini --set /etc/nova/nova.conf keystone_authtoken project_name service
crudini --set /etc/nova/nova.conf keystone_authtoken username nova
crudini --set /etc/nova/nova.conf keystone_authtoken password ${STACK_PASSWD}

crudini --set /etc/nova/nova.conf vnc enabled true
crudini --set /etc/nova/nova.conf vnc server_listen 0.0.0.0
crudini --set /etc/nova/nova.conf vnc server_proxyclient_address \$my_ip
crudini --set /etc/nova/nova.conf vnc novncproxy_base_url http://${CON_IP}:6080/vnc_auto.html

crudini --set /etc/nova/nova.conf glance api_servers http://${CON_IP}:9292

crudini --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp

crudini --set /etc/nova/nova.conf placement region_name RegionOne
crudini --set /etc/nova/nova.conf placement project_domain_name Default
crudini --set /etc/nova/nova.conf placement project_name service
crudini --set /etc/nova/nova.conf placement auth_type password
crudini --set /etc/nova/nova.conf placement user_domain_name Default
crudini --set /etc/nova/nova.conf placement auth_url http://${CON_IP}:5000/v3
crudini --set /etc/nova/nova.conf placement username placement
crudini --set /etc/nova/nova.conf placement password ${STACK_PASSWD}


##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "HYPER ACC. ..."
egrep -c '(vmx|svm)' /proc/cpuinfo


##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "NOVA CONF. ..."
crudini --set /etc/nova/nova-compute.conf libvirt virt_type kvm


##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "SERVICE RESTART ..."
service nova-compute restart

