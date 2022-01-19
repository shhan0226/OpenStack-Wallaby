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
read -p "Input Contorller IP (ex.192.168.0.2) : " CONTROLLER_IP
read -p "Input Compute IP (ex.192.168.0.3) : " COMPUTE_IP
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
apt upgrade -y

##################################
# Install python
##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Python & pip SET ..."
echo "ubuntu 20.04 ........."
apt install python3-pip -y
sudo apt install net-tools -y
sudo apt install -y software-properties-common build-essential python3 python3-pip python-is-python3 libgtk-3-dev python3-etcd3gw

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
apt install chrony -y
echo "server $CONTROLLER_IP iburst" >> /etc/chrony/chrony.conf
echo "allow $SET_IP_ALLOW" >> /etc/chrony/chrony.conf
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
apt upgrade -y
apt install python3-openstackclient -y
openstack --version

##################################
# Openstack Mariadb Set ...
##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Openstack Mariadb Set ..."
touch /etc/mysql/mariadb.conf.d/99-openstack.cnf
crudini --set /etc/mysql/mariadb.conf.d/99-openstack.cnf mysqld bind-address $CONTROLLER_IP
crudini --set /etc/mysql/mariadb.conf.d/99-openstack.cnf mysqld default-storage-engine innodb
crudini --set /etc/mysql/mariadb.conf.d/99-openstack.cnf mysqld innodb_file_per_table on
crudini --set /etc/mysql/mariadb.conf.d/99-openstack.cnf mysqld max_connections 4096
crudini --set /etc/mysql/mariadb.conf.d/99-openstack.cnf mysqld collation-server utf8_general_ci
crudini --set /etc/mysql/mariadb.conf.d/99-openstack.cnf mysqld character-set-server utf8

service mysql restart
echo -e "\ny\ny\nstack\nstack\ny\ny\ny\ny" | mysql_secure_installation

##################################
# Install Message queue ...
##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Install Message queue ..."
apt install rabbitmq-server -y
rabbitmqctl add_user openstack stack
sync
rabbitmqctl set_permissions openstack ".*" ".*" ".*"
sync

##################################
# Install Memcached ...
##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Install Memcached ..."
apt install memcached -y
apt install python3-memcache -y
sed -i s/127.0.0.1/${CONTROLLER_IP}/ /etc/memcached.conf
service memcached restart

##################################
# Install ETCD ...
##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Install ETCD ..."
sync
wget https://github.com/etcd-io/etcd/releases/download/v3.4.1/etcd-v3.4.1-linux-arm64.tar.gz
tar -xvf etcd-v3.4.1-linux-arm64.tar.gz
sudo cp etcd-v3.4.1-linux-arm64/etcd* /usr/bin/
sync
sudo groupadd --system etcd
sudo useradd --home-dir "/var/lib/etcd" \
        --system \
        --shell /bin/false \
        -g etcd \
        etcd

sudo mkdir -p /etc/etcd
sudo chown etcd:etcd /etc/etcd
sudo mkdir -p /var/lib/etcd
sudo chown etcd:etcd /var/lib/etcd
sync
touch /etc/etcd/etcd.conf.yml
echo "name: controller" >> /etc/etcd/etcd.conf.yml
echo "data-dir: /var/lib/etcd" >> /etc/etcd/etcd.conf.yml
echo "initial-cluster-state: \'new\'" >> /etc/etcd/etcd.conf.yml
echo "initial-cluster-token: \'etcd-cluster-01\'" >> /etc/etcd/etcd.conf.yml
echo "initial-cluster: controller=http://${CONTROLLER_IP}:2380" >> /etc/etcd/etcd.conf.yml
echo "initial-advertise-peer-urls: http://${CONTROLLER_IP}:2380" >> /etc/etcd/etcd.conf.yml
echo "advertise-client-urls: http://${CONTROLLER_IP}:2379" >> /etc/etcd/etcd.conf.yml
echo "listen-peer-urls: http://0.0.0.0:2380" >> /etc/etcd/etcd.conf.yml
echo "listen-client-urls: http://${CONTROLLER_IP}:2379" >> /etc/etcd/etcd.conf.yml
sync
touch /lib/systemd/system/etcd.service
echo "[Unit]" >> /lib/systemd/system/etcd.service
echo "Description=etcd - highly-available key value store">> /lib/systemd/system/etcd.service
echo "Documentation=https://github.com/coreos/etcd" >> /lib/systemd/system/etcd.service
echo "Documentation=man:etcd" >> /lib/systemd/system/etcd.service
echo "After=network.target" >> /lib/systemd/system/etcd.service
echo "Wants=network-online.target" >> /lib/systemd/system/etcd.service
echo " " >> /lib/systemd/system/etcd.service
echo "[Service]" >> /lib/systemd/system/etcd.service
echo "Environment=DAEMON_ARGS=" >> /lib/systemd/system/etcd.service
echo "Environment=ETCD_NAME=%H" >> /lib/systemd/system/etcd.service
echo "Environment=ETCD_DATA_DIR=/vara/lib/etcd/default" >> /lib/systemd/system/etcd.service
echo "Environment=\"ETCD_UNSUPPORTED_ARCH=arm64\"" >> /lib/systemd/system/etcd.service
echo "EnvironmentFile=-/etc/default/%p" >> /lib/systemd/system/etcd.service
echo "Type=notify" >> /lib/systemd/system/etcd.service
echo "User=etcd" >> /lib/systemd/system/etcd.service
echo "PermissionsStartOnly=true" >> /lib/systemd/system/etcd.service
echo "ExecStart=/usr/bin/etcd --config-file /etc/etcd/etcd.conf.yml" >> /lib/systemd/system/etcd.service
echo "Restart=on-abnormal" >> /lib/systemd/system/etcd.service
echo "LimitNOFILE=65536" >> /lib/systemd/system/etcd.service
echo " " >> /lib/systemd/system/etcd.service
echo "[Install]" >> /lib/systemd/system/etcd.service
echo "WantedBy=multi-user.target" >> /lib/systemd/system/etcd.service
echo "Alias=etcd2.service" >> /lib/systemd/system/etcd.service
sync
sudo systemctl daemon-reload
sudo systemctl enable etcd
sudo systemctl restart etcd

##################################
# apt update
##################################
apt update -y
apt upgrade -y
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

##########################################
# keystone
##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Keystone Reg. Mariadb ..."
mysql -e "CREATE DATABASE keystone;"
mysql -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '${STACK_PASSWD}';"
mysql -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '${STACK_PASSWD}';"
mysql -e "FLUSH PRIVILEGES"

##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Install Keystone ..."
apt install keystone -y
apt install -y apache2 libapache2-mod-wsgi-py3 python3-oauth2client
crudini --set /etc/keystone/keystone.conf database connection mysql+pymysql://keystone:${STACK_PASSWD}@${CONTROLLER_IP}/keystone
crudini --set /etc/keystone/keystone.conf token provider fernet

##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Input DB ..."
su -s /bin/sh -c "keystone-manage db_sync" keystone
sync
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Keystone Bootstrap ..."
keystone-manage bootstrap --bootstrap-password ${STACK_PASSWD} --bootstrap-admin-url http://${CONTROLLER_IP}:5000/v3/ --bootstrap-internal-url http://${CONTROLLER_IP}:5000/v3/ --bootstrap-public-url http://${CONTROLLER_IP}:5000/v3/ --bootstrap-region-id RegionOne

##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"

systemctl daemon-reload

echo "apache2 ..."
echo "ServerName controller" >> /etc/apache2/apache2.conf
cd ~
sync
service apache2 restart

##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Input admin-openrc"
cat << EOF > admin-openrc
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=${STACK_PASSWD}
export OS_AUTH_URL=http://${CONTROLLER_IP}:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF

echo "Input demo-openrc"
cat << EOF > demo-openrc
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=myproject
export OS_USERNAME=myuser
export OS_PASSWORD=${STACK_PASSWD}
export OS_AUTH_URL=http://${CONTROLLER_IP}:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF

##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Openstack set ..."
. admin-openrc

openstack domain create --description "An Example Domain" example
openstack project create --domain default  --description "Service Project" service
openstack project create --domain default --description "Demo Project" myproject
openstack user create --domain default --password ${STACK_PASSWD} myuser
openstack role create myrole
openstack role add --project myproject --user myuser myrole

unset OS_AUTH_URL OS_PASSWORD
openstack --os-auth-url http://${CONTROLLER_IP}:5000/v3 --os-project-domain-name Default --os-password ${STACK_PASSWD} --os-user-domain-name Default --os-project-name admin --os-username admin token issue
openstack --os-auth-url http://${CONTROLLER_IP}:5000/v3 --os-project-domain-name Default --os-password ${STACK_PASSWD} --os-user-domain-name Default --os-project-name myproject --os-username myuser token issue

##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
. admin-openrc
openstack token issue

##########################################
# Glance
##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "GLANCE Reg. Mariadb ..."
mysql -e "CREATE DATABASE glance;"
mysql -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '${STACK_PASSWD}';"
mysql -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '${STACK_PASSWD}';"
mysql -e "FLUSH PRIVILEGES"

##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Openstack Glance ..."
. admin-openrc

openstack user create --domain default --password ${STACK_PASSWD} glance
openstack role add --project service --user glance admin
openstack service create --name glance --description "OpenStack Image" image

openstack endpoint create --region RegionOne image public http://${CONTROLLER_IP}:9292
openstack endpoint create --region RegionOne image internal http://${CONTROLLER_IP}:9292
openstack endpoint create --region RegionOne image admin http://${CONTROLLER_IP}:9292

##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Install Glance ..."
apt install glance -y

crudini --set /etc/glance/glance-api.conf database connection mysql+pymysql://glance:${STACK_PASSWD}@${CONTROLLER_IP}/glance
crudini --set /etc/glance/glance-api.conf keystone_authtoken www_authenticate_uri http://${CONTROLLER_IP}:5000
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_url http://${CONTROLLER_IP}:5000
crudini --set /etc/glance/glance-api.conf keystone_authtoken memcached_servers ${CONTROLLER_IP}:11211
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_type password
crudini --set /etc/glance/glance-api.conf keystone_authtoken project_domain_name Default
crudini --set /etc/glance/glance-api.conf keystone_authtoken user_domain_name Default
crudini --set /etc/glance/glance-api.conf keystone_authtoken project_name service
crudini --set /etc/glance/glance-api.conf keystone_authtoken username glance
crudini --set /etc/glance/glance-api.conf keystone_authtoken password ${STACK_PASSWD}

crudini --set /etc/glance/glance-api.conf paste_deploy flavor keystone
crudini --set /etc/glance/glance-api.conf glance_store stores file,http
crudini --set /etc/glance/glance-api.conf glance_store default_store file
crudini --set /etc/glance/glance-api.conf glance_store filesystem_store_datadir /var/lib/glance/images/

##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Input DB ..."
su -s /bin/sh -c "glance-manage db_sync" glance

##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "service restart"
service glance-api restart

##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "download img"
. admin-openrc
wget http://download.cirros-cloud.net/0.5.1/cirros-0.5.1-arm-disk.img
sync

##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "create image ..."
systemctl daemon-reload
service glance-api restart
sync
. admin-openrc
openstack image list

#glance image-create --name "cirros" --file cirros-0.5.1-arm-disk.img --disk-format qcow2 --container-format bare --visibility=public
openstack image create "cirros" --file cirros-0.5.1-arm-disk.img --disk-format qcow2 --container-format bare --public
sync
#glance image-list
openstack image list

##########################################
# Placement
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

openstack endpoint create --region RegionOne placement public http://${CONTROLLER_IP}:8778
openstack endpoint create --region RegionOne placement internal http://${CONTROLLER_IP}:8778
openstack endpoint create --region RegionOne placement admin http://${CONTROLLER_IP}:8778

##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Install Placement ..."

apt install placement-api -y

crudini --set /etc/placement/placement.conf placement_database connection mysql+pymysql://placement:${STACK_PASSWD}@${CONTROLLER_IP}/placement
crudini --set /etc/placement/placement.conf api auth_strategy keystone
crudini --set /etc/placement/placement.conf keystone_authtoken auth_url http://${CONTROLLER_IP}:5000/v3   
crudini --set /etc/placement/placement.conf keystone_authtoken memcached_servers ${CONTROLLER_IP}:11211
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

##########################################
# Nova
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

openstack endpoint create --region RegionOne compute public http://${CONTROLLER_IP}:8774/v2.1
openstack endpoint create --region RegionOne compute internal http://${CONTROLLER_IP}:8774/v2.1
openstack endpoint create --region RegionOne compute admin http://${CONTROLLER_IP}:8774/v2.1

##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Install Nova Packages ..."
apt install -y nova-api nova-conductor nova-novncproxy nova-scheduler 

crudini --set /etc/nova/nova.conf api_database connection mysql+pymysql://nova:${STACK_PASSWD}@${CONTROLLER_IP}/nova_api
crudini --set /etc/nova/nova.conf database connection mysql+pymysql://nova:${STACK_PASSWD}@${CONTROLLER_IP}/nova
crudini --set /etc/nova/nova.conf DEFAULT transport_url rabbit://openstack:${STACK_PASSWD}@${CONTROLLER_IP}:5672/
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
crudini --set /etc/nova/nova.conf DEFAULT my_ip ${CONTROLLER_IP}
crudini --set /etc/nova/nova.conf vnc enabled true
crudini --set /etc/nova/nova.conf vnc server_listen \$my_ip
crudini --set /etc/nova/nova.conf vnc server_proxyclient_address \$my_ip
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

crudini --set /etc/nova/nova.conf DEFAULT use_neutron true
crudini --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver

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
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart
sync

##########################################
echo "###################################"
echo "Insert Nova-Compute ..."
echo "cp ./OpenStack-Wallaby/nova-check-to-compute.sh . "
echo "./nova-check-to-compute.sh"
echo "cp ./OpenStack-Wallaby/neutron-controller-wallaby.sh . "
echo "./neutron-controller-wallaby.sh"
echo "cp OpenStack-Wallaby/horizon-wallaby.sh . "
echo "./horizon-wallaby.sh"
