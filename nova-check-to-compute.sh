#!/bin/bash

##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "DB REG. ..."
. admin-openrc
# nova-manage cell_v2 discover_hosts
openstack compute service list --service nova-compute
su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova
crudini --set /etc/nova/nova.conf scheduler discover_hosts_in_cells_interval 300

##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Node Check ..."
. admin-openrc
openstack compute service list
openstack catalog list
openstack image list
nova-status upgrade check

