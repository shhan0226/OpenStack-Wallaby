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
read -p "Input Contorller IP: (ex.192.168.0.2) " CON_IP
read -p "Input Compute IP: (ex.192.168.0.3) " SET_IP
read -p "What is openstack passwrd? : " STACK_PASSWD
echo "$STACK_PASSWD"
sync

##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Install KVM ..."
apt-get install qemu -y
apt-get install qemu-kvm -y
#apt-get install libvirt-bin -y
apt-get install libvirt-daemon-system -y
apt-get install libvirt-clients -y
apt-get install virtinst -y
apt-get install bridge-utils -y
apt-get install cpu-checker -y
apt-get install virt-manager -y 
apt-get install qemu-efi -y
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
sync

##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "NOVA Conf. ..."

crudini --set /etc/nova/nova.conf DEFAULT transport_url rabbit://openstack:${STACK_PASSWD}@controller
#crudini --set /etc/nova/nova.conf DEFAULT transport_url rabbit://openstack:${STACK_PASSWD}@${CON_IP}
crudini --set /etc/nova/nova.conf api auth_strategy keystone

crudini --set /etc/nova/nova.conf keystone_authtoken www_authenticate_uri http://controller:5000/
#crudini --set /etc/nova/nova.conf keystone_authtoken www_authenticate_uri http://${CON_IP}:5000/
crudini --set /etc/nova/nova.conf keystone_authtoken auth_url http://controller:5000/
#crudini --set /etc/nova/nova.conf keystone_authtoken auth_url http://${CON_IP}:5000/
crudini --set /etc/nova/nova.conf keystone_authtoken memcached_servers controller:11211
#crudini --set /etc/nova/nova.conf keystone_authtoken memcached_servers ${CON_IP}:11211
crudini --set /etc/nova/nova.conf keystone_authtoken auth_type password
crudini --set /etc/nova/nova.conf keystone_authtoken project_domain_name Default
crudini --set /etc/nova/nova.conf keystone_authtoken user_domain_name Default
crudini --set /etc/nova/nova.conf keystone_authtoken project_name service
crudini --set /etc/nova/nova.conf keystone_authtoken username nova
crudini --set /etc/nova/nova.conf keystone_authtoken password ${STACK_PASSWD}

crudini --set /etc/nova/nova.conf DEFAULT my_ip ${SET_IP}
crudini --set /etc/nova/nova.conf vnc enabled true
crudini --set /etc/nova/nova.conf vnc server_listen 0.0.0.0
crudini --set /etc/nova/nova.conf vnc server_proxyclient_address \$my_ip
crudini --set /etc/nova/nova.conf vnc novncproxy_base_url http://controller:6080/vnc_auto.html
#crudini --set /etc/nova/nova.conf vnc novncproxy_base_url http://${CON_IP}:6080/vnc_auto.html
crudini --set /etc/nova/nova.conf glance api_servers http://controller:9292
#crudini --set /etc/nova/nova.conf glance api_servers http://${CON_IP}:9292
crudini --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp
crudini --set /etc/nova/nova.conf placement region_name RegionOne
crudini --set /etc/nova/nova.conf placement project_domain_name Default
crudini --set /etc/nova/nova.conf placement project_name service
crudini --set /etc/nova/nova.conf placement auth_type password
crudini --set /etc/nova/nova.conf placement user_domain_name Default
crudini --set /etc/nova/nova.conf placement auth_url http://controller:5000/v3
#crudini --set /etc/nova/nova.conf placement auth_url http://${CON_IP}:5000/v3
crudini --set /etc/nova/nova.conf placement username placement
crudini --set /etc/nova/nova.conf placement password ${STACK_PASSWD}

sync

##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "HYPER ACC. ..."
egrep -c '(vmx|svm)' /proc/cpuinfo

##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "NOVA CONF. ..."
crudini --set /etc/nova/nova-compute.conf libvirt virt_type kvm
#crudini --set /etc/nova/nova-compute.conf libvirt virt_type qemu
sync

##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "SERVICE RESTART ..."
service nova-compute restart
#systemctl enable libvirtd.service openstack-nova-compute.service
#systemctl start libvirtd.service openstack-nova-compute.service

