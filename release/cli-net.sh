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
# download img
##################################
apt install wget -y
wget https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-arm64.img
sync


#################################
echo "Time Checker Start!!!!!!!!!"
StartTime=$(date +%s)


##################################
# create External Net
##################################
. admin-openrc
sync
echo "external net..."
openstack network create --external --provider-network-type flat --provider-physical-network provider external


##################################
# create Subnet External Net
##################################
. admin-openrc
ifconfig
echo "external sub net..."

openstack subnet create --subnet-range 192.168.0.0/22 --no-dhcp --gateway 192.168.0.1 --network external --dns-nameserver 8.8.8.8 --allocation-pool start=192.168.0.100,end=192.168.0.150 external-subnet

sync


##################################
# create Internal Net
##################################
. admin-openrc
sync
echo "internal net..."
openstack network create internal

sync


##################################
# create Subnet Internal Net
##################################
. admin-openrc
sync
echo "insternal sub net..."
openstack subnet create --subnet-range 172.16.0.0/24 --dhcp --network internal --dns-nameserver 8.8.8.8 internal-subnet
sync


##################################
# create Router
##################################
. admin-openrc
sync
echo "route create..."
openstack router create arm-router

echo "route in add..."
openstack router add subnet arm-router internal-subnet

echo "route ex add..."
openstack router set --external-gateway external arm-router

echo "route list..."
openstack router list
sync


##################################
# create keypair
##################################
. admin-openrc

echo "keypair list..."
openstack keypair list
openstack keypair create arm-key > arm-key.pem


##################################
# create Secu.
##################################
. admin-openrc

echo "security list..."
openstack security group create arm-secu

openstack security group rule create --remote-ip 0.0.0.0/0 --dst-port 22 --protocol tcp --ingress arm-secu

openstack security group rule create --remote-ip 0.0.0.0/0 --dst-port 80 --protocol tcp --ingress arm-secu

openstack security group rule create --remote-ip 0.0.0.0/0 --dst-port 8080 --protocol tcp --ingress arm-secu

openstack security group rule create --remote-ip 0.0.0.0/0 --dst-port 3306 --protocol tcp --ingress arm-secu

openstack security group rule create --remote-ip 0.0.0.0/0 --protocol icmp --ingress arm-secu

openstack security group show arm-secu


##################################
# create init.sh
##################################
. admin-openrc

cat << EOF >init.sh
#cloud-config
password: stack
chpasswd: { expire: False }
ssh_pwauth: True
EOF


##################################
# create flavor(Instance TEMP)
##################################
. admin-openrc

echo "create flavor..."
openstack flavor create --vcpus 4 --ram 4096 --disk 30 arm-flavor

echo "flavor list..."
openstack flavor list


##################################
# create img
##################################
. admin-openrc

echo "image create..."

glance image-create --name "ubuntu1804" \
        --file bionic-server-cloudimg-arm64.img \
        --disk-format qcow2 --container-format bare \
        --visibility=public


echo "image show..."
openstack image show ubuntu1804
sync


#################################
echo "Time Checker END!!!!!!!!!"
EndTime=$(date +%s)
echo "It takes $(($EndTime - $StartTime)) seconds to complete this task."

echo "END..."
