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
sudo apt install net-tools -y
ifconfig
read -p "Input Contorller IP: (ex.192.168.0.2) " SET_IP
read -p "Input Compute IP: (ex.192.168.0.3) " SET_IP2
read -p "please input the allow IP (ex 192.168.0.0/24): " SET_IP_ALLOW
read -p "Is this a Controller Node? <y|n>: " CONTROLLER_NODE
sync
echo "$SET_IP controller" >> /etc/hosts
echo "$SET_IP2 compute" >> /etc/hosts
echo "$SET_IP_ALLOW"

##################################
# update apt
##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "APT update..."
apt update -y
apt upgrade -y

##################################
# Install python
##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Python & pip SET ..."
echo "ubuntu 20.04 ........."
apt install -y software-properties-common
apt install -y build-essential
apt install -y python3 
apt install -y python3-pip
apt install -y python-is-python3 
apt install -y libgtk-3-dev 
apt install -y python3-etcd3gw

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
apt upgrade -y
apt install mariadb-server -y
apt install python3-pymysql -y

##################################
# Install NTP
##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "INSTALL NTP ..."

if [ "${CONTROLLER_NODE}" = "y" ]; then
	apt install chrony -y
	echo "server controller iburst" >> /etc/chrony/chrony.conf	
	echo "allow $SET_IP_ALLOW" >> /etc/chrony/chrony.conf
	service chrony restart
	chronyc sources
else
    apt install chrony -y
    sed -i 's/pool/#pool/' /etc/chrony/chrony.conf
    echo "server controller iburst" >> /etc/chrony/chrony.conf
    service chrony restart
    chronyc sources
fi

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
apt upgrade -y
apt install python3-openstackclient -y
openstack --version

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