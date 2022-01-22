i#!/bin/bash

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
read -p "Input Contorller IP: (ex.192.168.0.2) " SET_IP
read -p "What is openstack passwrd? : " STACK_PASSWD
echo "$STACK_PASSWD"
sync

##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Keystone Reg. Mariadb ..."
mysql -e "CREATE DATABASE keystone;"
mysql -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '${STACK_PASSWD}';"
mysql -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '${STACK_PASSWD}';"
mysql -e "FLUSH PRIVILEGES"
sync
##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Install Keystone ..."
apt install keystone -y

crudini --set /etc/keystone/keystone.conf database connection mysql+pymysql://keystone:${STACK_PASSWD}@${SET_IP}/keystone
crudini --set /etc/keystone/keystone.conf token provider fernet
sync
##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Input DB ..."
su -s /bin/sh -c "keystone-manage db_sync" keystone
sync
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
sync
##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Keystone Bootstrap ..."
keystone-manage bootstrap --bootstrap-password ${STACK_PASSWD} \
  --bootstrap-admin-url http://${SET_IP}:5000/v3/ \
  --bootstrap-internal-url http://${SET_IP}:5000/v3/ \
  --bootstrap-public-url http://${SET_IP}:5000/v3/ \
  --bootstrap-region-id RegionOne

sync
##########################################
#echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
#echo "devkit UI ..."
#systemctl stop devkit_flask.service
#systemctl daemon-reload

##########################################
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
export OS_AUTH_URL=http://${SET_IP}:5000/v3
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
export OS_AUTH_URL=http://${SET_IP}:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF

##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Openstack set ..."
. admin-openrc

openstack domain create --description "An Example Domain" example
sync
openstack project create --domain default  --description "Service Project" service
sync
openstack project create --domain default --description "Demo Project" myproject
sync
openstack user create --domain default --password ${STACK_PASSWD}  myuser
sync
openstack role create myrole
sync
openstack role add --project myproject --user myuser myrole
sync
unset OS_AUTH_URL OS_PASSWORD
sync
openstack --os-auth-url http://${SET_IP}:5000/v3 --os-project-domain-name Default --os-password ${STACK_PASSWD} --os-user-domain-name Default --os-project-name admin --os-username admin token issue
sync
openstack --os-auth-url http://${SET_IP}:5000/v3 --os-project-domain-name Default --os-password ${STACK_PASSWD} --os-user-domain-name Default --os-project-name myproject --os-username myuser token issue
sync

##########################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
. admin-openrc
openstack token issue