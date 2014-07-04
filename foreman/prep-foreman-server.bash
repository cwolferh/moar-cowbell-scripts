# Intended to be run on the foreman server.
#
# ***Before*** running foreman_server.sh:
#   copy $ASTAPOR to standard installer location
#   copy puppet-pacemaker puppet modules to standard installer location
#   set default test passwords instead of the default long random hex keys
#
# I prefer to do it this way rather than running foreman_server.sh
# straight from ASTAPOR.  bin/foreman-params.json gets rewritten in
# place.  So, if your ASTAPOR is a git checkout, now you've got
# updates.  And you've got the wrong values for say 'foreman_server'
# if you try running it on a different foreman server.  But worse,
# you've added chaos to the system if you rerun the installer (unless
# you git revert) on the fresh system.
#

JUST_SEEDS=${JUST_SEEDS:=false}
FROM_SOURCE=${FROM_SOURCE:=true}
ASTAPOR=${ASTAPOR:=/mnt/vm-share/astapor}
PUPPET_PACEMAKER=${PUPPET_PACEMAKER:=/mnt/vm-share/puppet-pacemaker}
PUPPET_GLUSTER=${PUPPET_GLUSTER:=/mnt/vm-share/puppet-openstack-storage}

#yum -y install /mnt/vm-share/tmp/openstack-puppet-modules-2013.2-9.el6ost.noarch.rpm
#yum -y install /mnt/vm-share/openstack-puppet-modules-2014.1-14.6.el7ost.noarch.rpm
yum -y install /mnt/vm-share/openstack-puppet-modules-2014.1-16.2.el7ost.noarch.rpm 

if [ "$FROM_SOURCE" = "true" ]; then
  mv /usr/share/openstack-foreman-installer /usr/share/openstack-foreman-installer-RPM-ORIG
  cp -ra $ASTAPOR /usr/share/openstack-foreman-installer
  find /usr/share/openstack-foreman-installer -name '.git' | xargs rm -rf
fi

 a hook for a wrapper script to have its way
if [ -f /mnt/vm-share/pre-foreman-install.bash ]; then
  bash -x /mnt/vm-share/pre-foreman-install.bash
fi

# easy default passwords please
perl -p -i -e 's/swift_shared_secret.*SecureRandom\.hex/swift_shared_secret"           => "123456"/g' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/mysql_root_password".*,/mysql_root_password"           => "mysqlrootpw",/g' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/keystone_db_password".*,/keystone_db_password"           => "123456",/g' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/glance_db_password".*,/glance_db_password"           => "123456",/g' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/nova_db_password".*,/nova_db_password"           => "123456",/g' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/cinder_db_password".*,/cinder_db_password"           => "123456",/g' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/heat_db_password".*,/heat_db_password"           => "123456",/g' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/neutron_db_password".*,/neutron_db_password"           => "123456",/g' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/"neutron".*,/"neutron"           => "true",/g' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/swift_local_interface".*,/swift_local_interface"           => "eth5",/g' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
#perl -p -i -e 's/ovs_vlan_ranges".*,/ovs_vlan_ranges"           => "physnet1:1000:2000",/g' \
perl -p -i -e 's/ovs_vlan_ranges".*,/ovs_vlan_ranges"           => "ext-vlan:1000:2000",/g' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/ovs_bridge_uplinks".*,/ovs_bridge_uplinks"           => \["br-ex:eth6"\],/g' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/ovs_bridge_mappings".*,/ovs_bridge_mappings"           => \["ext-vlan:br-ex"\],/g' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/tenant_network_type".*,/tenant_network_type"           => "vlan",/g' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/enable_tunneling".*,/enable_tunneling"           => "true",/g' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/swift_ring_server".*,/swift_ring_server"           => "192.168.111.55",/g' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e "s/SecureRandom\.hex/'weakpw'/g" \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/192.168.200.10 192.168.200.11 192.168.200.12/192.168.200.10 192.168.200.20 192.168.200.30/g' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/172.16.0.1/192.168.200.10/g' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/172.16.1.1/192.168.200.10/g' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(.*swift_all_ips.*=>\s?).*$/$1\["192.168.111.11", "192.168.111.12", "192.168.111.13", "192.168.111.14", "192.168.111.15", "192.168.111.16", "192.168.111.55"\],/g' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(.*lb_backend_server_addrs.*=>\s?).*$/$1\["192.168.200.10","192.168.200.20","192.168.200.30"\],/g' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(.*lb_backend_server_names.*=>\s?).*$/$1\["c1a1","c1a2","c1a3"\],/g' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(.*wsrep_cluster_members.*=>\s?).*$/$1\["192.168.200.10","192.168.200.20","192.168.200.30"\],/g' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "keystonerc"             =>  "true",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "storage_device"    =>  "192.168.111.100:\/mnt\/mysql",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "cinder_backend_volume"    =>  \["192.168.111.100:\/mnt\/cinder"\],\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "volume_backend"           =>  "nfs",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "storage_type"             =>  "nfs",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "secret_key"               =>  "123456",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "swift_shared_secret"      =>  "123456",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
#perl -p -i -e 's/(params = {\n)/$1  "swift_storage_ips"    =>  \["192.168.111.14","192.168.111.15","192.168.111.16"\],\n/' \
#  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "swift_storage_ips"    =>  \["192.168.111.14"\],\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "swift_storage_device"    =>  "device1",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "swift_internal_iface"    =>  "eth5",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "admin_token"    =>  "123456",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "db_password"    =>  "weakpw",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "db_vip"    =>  "192.168.201.7",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "keystone_public_vip"    =>  "192.168.201.33",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "keystone_private_vip"    =>  "192.168.201.34",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "keystone_admin_vip"    =>  "192.168.201.35",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "loadbalancer_vip"    =>  "192.168.201.53",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "glance_public_vip"    =>  "192.168.201.23",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "glance_private_vip"    =>  "192.168.201.24",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "glance_admin_vip"    =>  "192.168.201.25",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "nova_public_vip"    =>  "192.168.201.63",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "nova_private_vip"    =>  "192.168.201.64",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "nova_admin_vip"    =>  "192.168.201.65",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "swift_public_vip"    =>  "192.168.201.73",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "swift_internal_vip"    =>  "192.168.111.55",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "swift_admin_vip"    =>  "192.168.201.75",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "cinder_public_vip"    =>  "192.168.201.83",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "cinder_private_vip"    =>  "192.168.201.84",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "cinder_admin_vip"    =>  "192.168.201.85",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "horizon_public_vip"    =>  "192.168.201.93",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "horizon_private_vip"    =>  "192.168.201.94",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "horizon_admin_vip"    =>  "192.168.201.95",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "neutron_public_vip"    =>  "192.168.201.103",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "neutron_private_vip"    =>  "192.168.201.104",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "neutron_admin_vip"    =>  "192.168.201.105",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "heat_public_vip"    =>  "192.168.201.113",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "heat_private_vip"    =>  "192.168.201.114",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "heat_admin_vip"    =>  "192.168.201.115",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "heat_cfn_public_vip"    =>  "192.168.201.123",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "heat_cfn_private_vip"    =>  "192.168.201.124",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "heat_cfn_admin_vip"    =>  "192.168.201.125",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "amqp_vip"    =>  "192.168.201.13",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "backend_port"    =>  "5673",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "pcmk_fs_device"    =>  "192.168.200.100:\/mnt\/glance",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "pcmk_fs_manage"    =>  "true",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "include_cinder"    =>  "true",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "include_mysql"    =>  "true",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "include_glance"    =>  "true",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "include_keystone"    =>  "true",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "include_horizon"    =>  "true",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "include_nova"    =>  "true",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "include_neutron"    =>  "false",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "include_swift"    =>  "false",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "include_qpid"    =>  "false",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "include_rabbitmq"    =>  "true",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "fencing_type"    =>  "disabled",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "pcmk_fs_manage"    =>  "false",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "pcmk_swift_is_local"    =>  "false",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "pacemaker_cluster_members"    =>  "192.168.200.10 192.168.200.20 192.168.200.30",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "cluster_control_ip"    =>  "192.168.200.20",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "storage_options"    =>  "v3,context=\\"system_u:object_r:mysqld_db_t:s0\\"",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "neutron"    =>  "true",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "private_iface"    =>  "eth2",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "swift_iface"    =>  "eth5",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/(params = {\n)/$1  "ovs_tunnel_iface"    =>  "eth6",\n/' \
  /usr/share/openstack-foreman-installer/bin/seeds.rb
perl -p -i -e 's/rake db:seed/rake --trace db:seed/g' \
  /usr/share/openstack-foreman-installer/bin/foreman_server.sh

if [ "$JUST_SEEDS" = "true" ]; then
  exit 0
fi

#mkdir -p                /usr/share/openstack-puppet/modules
#rm -rf                  /usr/share/openstack-puppet/modules/xinetd
#cp -r /mnt/vm-share/puppetlabs-xinetd /usr/share/openstack-puppet/modules/xinetd
#ind /usr/share/openstack-puppet/modules/xinetd -name '.git' | xargs rm -rf

#mkdir -p                /usr/share/openstack-puppet/modules
#rm -rf                  /usr/share/openstack-puppet/modules/pacemaker
#cp -r $PUPPET_PACEMAKER /usr/share/openstack-puppet/modules/pacemaker
#find /usr/share/openstack-puppet/modules/pacemaker -name '.git' | xargs rm -rf



# testing openstack-puppet-modules
#yum -y install http://kojipkgs.fedoraproject.org/packages/openstack-puppet-modules/2013.2/4.el6/noarch/openstack-puppet-modules-2013.2-4.el6.noarch.rpm
#rpm -e --nodeps packstack-modules-puppet
#
#mkdir -p /usr/share/openstack-puppet/modules
#rm -rf  /usr/share/openstack-puppet/modules/pacemaker
#cp -r $PUPPET_PACEMAKER /usr/share/openstack-puppet/modules/pacemaker
#find /usr/share/openstack-puppet/modules/pacemaker -name '.git' | xargs rm -rf
#
#exit 0

# The Things They Carried
# (I could be talking about puppet-pacemaker, or I could be talking
#  about a great novel, highly recommended)
#
#mkdir -p /usr/share/packstack/modules
#rm -rf  /usr/share/packstack/modules/pacemaker
#cp -r $PUPPET_PACEMAKER /usr/share/packstack/modules/pacemaker
#find /usr/share/packstack/modules/pacemaker -name '.git' | xargs rm -rf

#
## gluster
#mkdir -p /usr/share/packstack/modules
#rm -rf  /usr/share/packstack/modules/gluster
#cp -r $PUPPET_GLUSTER /usr/share/packstack/modules/gluster
#find /usr/share/packstack/modules/gluster -name '.git' | xargs rm -rf



# below worked *before* pacemaker was added to packstack-modules-puppet
#mkdir -p /etc/puppet/environments/production/modules
#rm -rf  /etc/puppet/environments/production/modules/pacemaker
#cp -r $PUPPET_PACEMAKER /etc/puppet/environments/production/modules/pacemaker
#find /etc/puppet/environments/production/modules/pacemaker -name '.git' | xargs rm -rf
