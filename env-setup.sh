#!/bin/bash

#openstack-config --set /etc/neutron/plugins/ml2/ml2_conf.ini ovs bridge_mappings physnet1:br-ex

#service neutron-openvswitch-agent restart
#service neutron-server restart

# Cinder Configuration (a recent bug from packstack - https://bugzilla.redhat.com/show_bug.cgi?id=1272572)
sudo openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_uri http://192.168.1.10:5000
sudo openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_url http://192.168.1.10:35357
sudo openstack-config --set /etc/cinder/cinder.conf keystone_authtoken auth_plugin password
sudo openstack-config --set /etc/cinder/cinder.conf keystone_authtoken project_domain_id default
sudo openstack-config --set /etc/cinder/cinder.conf keystone_authtoken user_domain_id default
sudo openstack-config --set /etc/cinder/cinder.conf keystone_authtoken project_name services
sudo openstack-config --set /etc/cinder/cinder.conf keystone_authtoken username cinder
sudo openstack-config --set /etc/cinder/cinder.conf keystone_authtoken password cinderkspass

sudo service openstack-cinder-api restart
sudo service openstack-cinder-scheduler restart
sudo service openstack-cinder-volume restart
sudo service openstack-cinder-backup restart

# Load environment variables for admin user
export OS_USERNAME=admin
export OS_PASSWORD=adminkspass
export OS_AUTH_URL=http://192.168.1.10:5000/v2.0
export OS_TENANT_NAME=admin
export OS_REGION_NAME=RegionOne

# Upload Centos 7 image to Glance
sudo yum install -y wget
wget -nc http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud-1601.qcow2 -P /tmp
glance --os-image-api-version 2 image-create --name 'CentOS-7-x86_64' --disk-format qcow2 --container-format bare --visibility public --file /tmp/CentOS-7-x86_64-GenericCloud-1601.qcow2
wget -nc http://download.cirros-cloud.net/0.3.3/cirros-0.3.3-x86_64-disk.img -P /tmp
glance --os-image-api-version 2 image-create --name 'Cirros-0.3.3-x86_64' --disk-format qcow2 --container-format bare --visibility public --file /tmp/cirros-0.3.3-x86_64-disk.img


# Create tenant and user
openstack project create --description "Red Hat Cloud Assignment Project" redhat-cloud-assignment
openstack user create --password rhpass rhcloud
openstack role add --project redhat-cloud-assignment --user rhcloud _member_
openstack role add --project redhat-cloud-assignment --user rhcloud heat_stack_owner

# Create external network and subnet
neutron net-create --provider:network_type flat --provider:physical_network physnet1  --router:external --shared external_network
neutron subnet-create --name external_subnet --disable-dhcp --allocation-pool start=192.168.1.220,end=192.168.1.230 --gateway 192.168.1.1 external_network 192.168.1.0/24

# Load environment variables for rhcloud user
export OS_USERNAME=rhcloud
export OS_PASSWORD=rhpass
export OS_AUTH_URL=http://192.168.1.10:5000/v2.0
export OS_TENANT_NAME=redhat-cloud-assignment
export OS_REGION_NAME=RegionOne

# Create tenant network, subnet and router
neutron net-create private_network
neutron subnet-create --name private_subnet --allocation-pool start=172.10.0.10,end=172.10.0.250 private_network 172.10.0.0/24
neutron router-create rhcloud-router
neutron router-gateway-set rhcloud-router external_network
neutron router-interface-add rhcloud-router private_subnet

