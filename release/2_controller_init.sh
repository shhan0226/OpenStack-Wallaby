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

##################################
# Openstack Mariadb Set ...
##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Openstack Mariadb Set ..."
touch /etc/mysql/mariadb.conf.d/99-openstack.cnf
crudini --set /etc/mysql/mariadb.conf.d/99-openstack.cnf mysqld bind-address $SET_IP
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
sed -i s/127.0.0.1/${SET_IP}/ /etc/memcached.conf
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
echo "initial-cluster-state: 'new'" >> /etc/etcd/etcd.conf.yml
echo "initial-cluster-token: 'etcd-cluster-01'" >> /etc/etcd/etcd.conf.yml
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
