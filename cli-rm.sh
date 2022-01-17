. admin-openrc
openstack server list
read -p "Server ID? : " SERVER_ID
echo "$SERVER_ID"
read -p "floating IP ? : " F_IP
echo "$F_IP"

sync
echo "remove server"
. admin-openrc
openstack server remove floating ip $SERVER_ID $F_IP
openstack floating ip delete $F_IP
openstack server delete $SERVER_ID
sync
echo "remove image"
openstack image delete ubuntu1804
openstack flavor delete arm-flavor
rm -rf init.sh
sync
echo "remove security"
openstack security group delete arm-secu
openstack keypair delete arm-key
echo "remove router"
openstack router unset arm-router
openstack router remove subnet arm-router internal-subnet
openstack router delete arm-router
echo "remove network"
openstack network delete internal
openstack network delete external
