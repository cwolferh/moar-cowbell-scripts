foreman_node='s6fore1.example.com'

bash -x /mnt/pub/rdo/ha/reset-vms.bash
#rm /mnt/vm-share/modules/puppet-hamysql/*/*~
ssh root@$foreman_node "mkdir -p /etc/puppet/environments/production/modules/hamysql/manifests;
cp /mnt/vm-share/modules/puppet-hamysql/manifests/node.pp /etc/puppet/environments/production/modules/hamysql/manifests"
ssh -t root@$foreman_node "sudo -u foreman scl enable ruby193 'cd /usr/share/foreman; RAILS_ENV=production rake puppet:import:puppet_classes[batch]'"
for vm in s6ha1c1 s6ha1c2 s6ha1c3; do
  ssh root@$vm "yum-config-manager --enable rhel-ha-for-rhel-6-server-rpms"
done


# this is up2date w.r.t. dan's repo already 
#ssh root@$foreman_node "git clone https://github.com/radez/puppet-pacemaker.git /etc/puppet/environments/production/modules/pacemaker"
