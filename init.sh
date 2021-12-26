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
read -p "[python3 & pip] Is this os is ubuntu18.04? <y|n>: " PY_INSTALL
echo "$PY_INSTALL"

if [ "${PY_INSTALL}" = "y" ]; then
	apt install python3-pip -y
	update-alternatives --install /usr/bin/python python /usr/bin/python3.6 1
	update-alternatives --config python
	sudo -H pip3 install --upgrade pip
else
	apt install python3-pip -y
	sudo apt install software-properties-common build-essential python3 python3-pip python-is-python3 libgtk-3-dev -y
fi

##################################
# Install git
##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Install git ..."
apt install git -y
apt install wget -y

##################################
# Install grub-efi
##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Install grub ..."
read -p "[grub] Is this os is ubuntu18.04? <y|n>: " GRUB_INSTALL
echo "$GRUB_INSTALL"

if [ "${GRUB_INSTALL}" = "y" ]; then
	sudo apt-get purge grub\*
	apt install grub-common -y
	apt install grub2-common -y
	sudo apt-get autoremove -y
	sudo update-grub -y
	sync
fi

##################################
# Install Mariadb
##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Install Mariadb ..."
read -p "[Mariadb] Would you like to install it? <y|n>: " MARIADB_INSTALL
echo "$MARIADB_INSTALL"

if [ "${MARIADB_INSTALL}" = "y" ]; then
	sudo apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'
	sudo add-apt-repository 'deb [arch=amd64,arm64,ppc64el] https://ftp.harukasan.org/mariadb/repo/10.5/ubuntu bionic main'
	apt update -y
	apt dist-upgrade -y
	apt install mariadb-server -y
	apt install python3-pymysql -y
fi

##################################
# config /etc/hosts
##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "IP Setting ..."
ifconfig
read -p "Input Contorller IP: (ex.192.168.0.2) " SET_IP
read -p "Input Compute IP: (ex.192.168.0.3) " SET_IP2
echo "$SET_IP controller" >> /etc/hosts
echo "$SET_IP2 compute" >> /etc/hosts

##################################
# Install NTP
##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "INSTALL NTP ..."
read -p "[NTP] Is this a Controller Node? <y|n>: " CONTROLLER_NODE
sync

if [ "${CONTROLLER_NODE}" = "y" ]; then
	apt install chrony -y
	echo "server $SET_IP iburst" >> /etc/chrony/chrony.conf
	read -p "please input the allow IP (ex 192.168.0.0/24): " SET_IP_ALLOW
	echo "$SET_IP_ALLOW"
	echo "allow $SET_IP_ALLOW" >> /etc/chrony/chrony.conf
	service chrony restart
	chronyc sources

else
	read -p "[NTP] Is this a Compute Node? <y|n>: " COMPUTE_NODE
	sync
	if [ "${COMPUTE_NODE}" = "y" ]; then
        	apt install chrony -y
		sed -i 's/pool/#pool/' /etc/chrony/chrony.conf
        	echo "server controller iburst" >> /etc/chrony/chrony.conf
        	service chrony restart
        	chronyc sources
	fi	
fi

##################################
# NTP error?
##################################
read -p "[NTP] NTP ERROR? <y|n>: " NTP_ERROR
sync

if [ "${NTP_ERROR}" = "y" ]; then
        killall apt apt-get -y
	rm /var/lib/apt/lists/lock
	rm /var/cache/apt/archives/lock
	rm /var/lib/dpkg/lock*
	dpkg --configure -a 
	apt update -y
	cd ~
fi

##################################
# Install Simplejson
##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Install Simplejson ..."
read -p "[Simplejson] Would you like to install it? <y|n>: " SIMPLEJSON_INSTALL
#echo "$SIMPLEJSON_INSTALL"
sync

if [ "${SIMPLEJSON_INSTALL}" = "y" ]; then
	pip install simplejson
	sync
	pip install --ignore-installed simplejson
fi

##################################
# Install crudini
##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Install crudini ..."
read -p "[crudini] Would you like to install it? <y|n>: " CRUDINI_INSTALL
sync

if [ "${CRUDINI_INSTALL}" = "y" ]; then
	#apt install -y python3-iniparse
	#git clone https://github.com/pixelb/crudini.git
	#mv crudini /usr/bin/crudinid 
	#ln -s /usr/bin/crudinid/crudini /usr/bin/crudini
	
	wget https://github.com/pixelb/crudini/releases/download/0.9.3/crudini-0.9.3.tar.gz
    	tar xvf crudini-0.9.3.tar.gz
    	mv crudini-0.9.3/crudini /usr/bin/
    	pip3 install iniparse
    	rm -rf crudini-0.9.3 crudini-0.9.3.tar.gz
	
	sync
	cd ~
fi

##################################
# Install Openstack Client
##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Install Openstack Client ..."
read -p "[Openstack-client] Would you like to install it? <y|n>: " OPENSTACKCLIENT_INSTALL
sync

if [ "${OPENSTACKCLIENT_INSTALL}" = "y" ]; then
	sudo add-apt-repository cloud-archive:wallaby -y
	apt update -y
        apt dist-upgrade -y
	apt install python3-openstackclient -y
	openstack --version
fi


##################################
# Openstack Mariadb Set ...
##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Openstack Mariadb Set ..."
read -p "[Openstack-Mariadb] Would you like to setting it? <y|n>: " OPENSTACK_DB_SET
sync

if [ "${OPENSTACK_DB_SET}" = "y" ]; then

        touch /etc/mysql/mariadb.conf.d/99-openstack.cnf
        crudini --set /etc/mysql/mariadb.conf.d/99-openstack.cnf mysqld bind-address $SET_IP
        crudini --set /etc/mysql/mariadb.conf.d/99-openstack.cnf mysqld default-storage-engine innodb
        crudini --set /etc/mysql/mariadb.conf.d/99-openstack.cnf mysqld innodb_file_per_table on
        crudini --set /etc/mysql/mariadb.conf.d/99-openstack.cnf mysqld max_connections 4096
        crudini --set /etc/mysql/mariadb.conf.d/99-openstack.cnf mysqld collation-server utf8_general_ci
        crudini --set /etc/mysql/mariadb.conf.d/99-openstack.cnf mysqld character-set-server utf8
	
	service mysql restart
	echo -e "\ny\ny\nstack\nstack\ny\ny\ny\ny" | mysql_secure_installation
fi

##################################
# Install Message queue ...
##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Install Message queue ..."
read -p "[rabbitmq-server] Would you like to install it? <y|n>: " RABBIT_INSTALL
sync

if [ "${RABBIT_INSTALL}" = "y" ]; then
	apt install rabbitmq-server -y
	rabbitmqctl add_user openstack stack
	sync
	rabbitmqctl set_permissions openstack ".*" ".*" ".*"
	sync

fi

##################################
# Install Memcached ...
##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Install Memcached ..."
read -p "[Memcached] Would you like to install it? <y|n>: " MAMCACHED_INSTALL
sync

if [ "${MAMCACHED_INSTALL}" = "y" ]; then
        apt install memcached -y
        apt install python3-memcache -y
        sed -i s/127.0.0.1/${SET_IP}/ /etc/memcached.conf
        service memcached restart
fi

##################################
# Install ETCD ...
##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Install ETCD ..."
read -p "[Etcd] Would you like to install it? <y|n>: " ETCD_INSTALL
sync

if [ "${ETCD_INSTALL}" = "y" ]; then
	#groupadd --system etcd
	#useradd --home-dir "/var/lib/etcd" --system --shell /bin/false -g etcd etcd
	#mkdir -p /etc/etcd
	#chown etcd:etcd /etc/etcd
	#mkdir -p /var/lib/etcd
	#chown etcd:etcd /var/lib/etcd
	
	#wget https://github.com/etcd-io/etcd/releases/download/v3.4.1/etcd-v3.4.1-linux-arm64.tar.gz
	#tar -xvf etcd-v3.4.1-linux-arm64.tar.gz
	#sudo cp etcd-v3.4.1-linux-arm64/etcd* /usr/bin/
	sync
	wget https://github.com/etcd-io/etcd/releases/download/v3.4.1/etcd-v3.4.1-linux-arm64.tar.gz
	tar -xvf etcd-v3.4.1-linux-arm64.tar.gz
	sudo cp etcd-v3.4.1-linux-arm64/etcd* /usr/bin/

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
	echo "initial-cluster: controller=http://${SET_IP}:2380" >> /etc/etcd/etcd.conf.yml
	echo "initial-advertise-peer-urls: http://${SET_IP}:2380" >> /etc/etcd/etcd.conf.yml
	echo "advertise-client-urls: http://${SET_IP}:2379" >> /etc/etcd/etcd.conf.yml
	echo "listen-peer-urls: http://0.0.0.0:2380" >> /etc/etcd/etcd.conf.yml
	echo "listen-client-urls: http://${SET_IP}:2379" >> /etc/etcd/etcd.conf.yml
	
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

fi

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
