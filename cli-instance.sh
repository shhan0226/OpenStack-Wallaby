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


#################################
echo "Time Checker Start!!!!!!!!!"
StartTime=$(date +%s)


##################################
echo "server create..."
#. demo-openrc
. admin-openrc
#openstack server create --image ubuntu1804 --flavor arm-flavor --key-name arm-key --network internal --user-data init.sh --security-group arm-secu Web-instance
openstack server create --image ubuntu2004 --flavor arm-flavor --key-name arm-key --network internal --security-group arm-secu Web-instance

echo "server list..."
openstack server list


#################################
echo "Time Checker END!!!!!!!!!"
EndTime=$(date +%s)
echo "It takes $(($EndTime - $StartTime)) seconds to complete this task."


##################################
# Add Floating IP
##################################
#. demo-openrc
. admin-openrc
echo "floating ip create..."
openstack floating ip create external

read -p "Input floating IP: " F_IP
sync
echo "db-instance ${F_IP}"
sync

#. demo-openrc
. admin-openrc
echo "server add floating ip..."
openstack server add floating ip Web-instance ${F_IP}

chmod 400 arm-key.pem
echo "================================="
echo "ssh -i arm-key.pem ubuntu@${F_IP}"
echo "================================="
echo "END..."
