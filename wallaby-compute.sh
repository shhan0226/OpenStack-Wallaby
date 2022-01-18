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
read -p "Input Contorller IP: (ex.192.168.0.2) " CONTROLLER_IP
read -p "Input Compute IP: (ex.192.168.0.3) " COMPUTE_IP
echo "$CONTROLLER_IP controller" >> /etc/hosts
echo "$COMPUTE_IP compute" >> /etc/hosts

##################################
# stack passwrd
##################################
read -p "What is openstack passwrd? : " STACK_PASSWD
echo "$STACK_PASSWD"

read -p "please input the allow IP (ex 192.168.0.0/24): " SET_IP_ALLOW
echo "$SET_IP_ALLOW"


##################################
# update apt
##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "APT update..."
apt update -y
apt dist-upgrade -y

##################################
# Install python
##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Python & pip SET ..."
echo "ubuntu 20.04 ........."
apt install python3-pip -y
sudo apt install net-tools software-properties-common build-essential python3 python3-pip python-is-python3 libgtk-3-dev python3-etcd3gw -y
sudo apt install net-tools -y

##################################
# Install git
##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Install git ..."
apt install git -y
apt install wget -y

##################################
# Install Mariadb
##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Install Mariadb ..."
sudo apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'
sudo add-apt-repository 'deb [arch=amd64,arm64,ppc64el] https://ftp.harukasan.org/mariadb/repo/10.5/ubuntu bionic main'
apt update -y
apt dist-upgrade -y
apt install mariadb-server -y
apt install python3-pymysql -y

##################################
# Install NTP
##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "INSTALL NTP ..."
apt install chrony -y
sed -i 's/pool/#pool/' /etc/chrony/chrony.conf
echo "server $CONTROLLER_IP iburst" >> /etc/chrony/chrony.conf
service chrony restart
chronyc sources

##################################
# Install Simplejson
##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Install Simplejson ..."
pip install simplejson
sync
pip install --ignore-installed simplejson

##################################
# Install crudini
##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Install crudini ..."
wget https://github.com/pixelb/crudini/releases/download/0.9.3/crudini-0.9.3.tar.gz
tar xvf crudini-0.9.3.tar.gz
mv crudini-0.9.3/crudini /usr/bin/
pip3 install iniparse
rm -rf crudini-0.9.3 crudini-0.9.3.tar.gz

sync
cd ~

##################################
# Install Openstack Client
##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Install Openstack Client ..."
sudo add-apt-repository cloud-archive:wallaby -y
apt update -y
apt dist-upgrade -y
apt install python3-openstackclient -y
openstack --version


##################################
# apt update
##################################
apt update -y
apt dist-upgrade -y
apt autoremove -y
echo "=========================================================="
echo "Openstack installation END !!!"
openstack --version
echo "=========================================================="
echo " "
python --version
pip --version
echo "----------------------------------------------------------"
service --status-all|grep +
echo ">"
echo "----------------------------------------------------------"
echo "THE END !!!"


##################################
# nova
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
sync
sudo adduser $USER kvm
sync
kvm-ok

##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Install NOVA-Compute ..."
apt install nova-compute -y

##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "NOVA Conf. ..."

crudini --set /etc/nova/nova.conf DEFAULT transport_url rabbit://openstack:stack@${CONTROLLER_IP}
crudini --set /etc/nova/nova.conf api auth_strategy keystone
crudini --set /etc/nova/nova.conf keystone_authtoken www_authenticate_uri http://${CONTROLLER_IP}:5000/
crudini --set /etc/nova/nova.conf keystone_authtoken auth_url http://${CONTROLLER_IP}:5000/
crudini --set /etc/nova/nova.conf keystone_authtoken memcached_servers ${CONTROLLER_IP}:11211
crudini --set /etc/nova/nova.conf keystone_authtoken auth_type password
crudini --set /etc/nova/nova.conf keystone_authtoken project_domain_name Default
crudini --set /etc/nova/nova.conf keystone_authtoken user_domain_name Default
crudini --set /etc/nova/nova.conf keystone_authtoken project_name service
crudini --set /etc/nova/nova.conf keystone_authtoken username nova
crudini --set /etc/nova/nova.conf keystone_authtoken password ${STACK_PASSWD}
crudini --set /etc/nova/nova.conf DEFAULT my_ip ${COMPUTE_IP}
crudini --set /etc/nova/nova.conf vnc enabled true
crudini --set /etc/nova/nova.conf vnc server_listen 0.0.0.0
crudini --set /etc/nova/nova.conf vnc server_proxyclient_address \$my_ip
crudini --set /etc/nova/nova.conf vnc novncproxy_base_url http://${CONTROLLER_IP}:6080/vnc_auto.html
crudini --set /etc/nova/nova.conf glance api_servers http://${CONTROLLER_IP}:9292
crudini --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp
crudini --set /etc/nova/nova.conf placement region_name RegionOne
crudini --set /etc/nova/nova.conf placement project_domain_name Default
crudini --set /etc/nova/nova.conf placement project_name service
crudini --set /etc/nova/nova.conf placement auth_type password
crudini --set /etc/nova/nova.conf placement user_domain_name Default
crudini --set /etc/nova/nova.conf placement auth_url http://${CONTROLLER_IP}:5000/v3
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
