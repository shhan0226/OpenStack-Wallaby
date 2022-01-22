#!/bin/bash

##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "compute server list ...."
. admin-openrc
openstack compute service list --service nova-compute

echo "cell_v2 discover hosts ..."
su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova

echo "interval set ..."
crudini --set /etc/nova/nova.conf scheduler discover_hosts_in_cells_interval 300

##################################
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo "Node Check ..."
. admin-openrc
openstack compute service list
openstack catalog list
openstack image list
nova-status upgrade check