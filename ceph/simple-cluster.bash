#!/bin/bash
#
# Note there some interactive prompts in this script, so be prepared
# to respond to those.
#
# This should set up one node with a single osd and a few monitors.
# Make sure to set the following *name* vars with vm's that make sense
# for your setup.
#
# Typical order of operations:
#  * get an HA-all-in-one-controller running on nodes $monnames
#  * run bm-simple-server-prep.bash on the bare-metal host (make sure
#     $nodename in that script is correct, it should be the same as
#     $osdnodename below)
#  * run this script *on the $osdnodename vm*


ice_tarball=/mnt/vm-share/ice12/ICE-1.2-rhel7.tar.gz
icedir=/mnt/vm-share/ice-work5
nodenames="c1a1 c1a2 c1a3 c1a4"
monnames="c1a1 c1a2 c1a3"
#nodenames="c1a1 c1a4"
#monnames="c1a1"
osdnodename=c1a4

setup_ice_repo() {
  mkdir -p $icedir
  cd $icedir
  tar -zxvf $ice_tarball -C $icedir
  python $icedir/ice_setup.py
}

setup_ice_repo
cd $icedir

calamari-ctl initialize

ceph-deploy purge $nodenames
ceph-dpeloy purgedata $nodenames

ceph-deploy new $nodenames
echo 'osd pool default size = 1' >> ceph.conf
echo 'osd journal size = 1000' >> ceph.conf
echo 'HIT A KEY TO CONTINUE'; read

ceph-deploy install $nodenames
echo 'HIT A KEY TO CONTINUE'; read

ceph-deploy mon create-initial
echo 'HIT A KEY TO CONTINUE'; read

ceph-deploy mon create $monnames
echo 'HIT A KEY TO CONTINUE'; read

ceph-deploy gatherkeys $nodenames

echo 'HIT A KEY TO CONTINUE'; read

mkdir /osd0
ceph-deploy osd prepare $osdnodename:/osd0
ceph-deploy osd activate $osdnodename:/osd0
ceph-deploy mds create $osdnodename

# creating backups though may not be necessary if cinder-backup
# service not running

ceph osd pool create volumes 128
ceph osd pool create images 128
#ceph osd pool create backups 128

ceph-authtool --create-keyring /etc/ceph/ceph.client.images.keyring
chmod +r /etc/ceph/ceph.client.images.keyring
ceph-authtool /etc/ceph/ceph.client.images.keyring -n client.images --gen-key
ceph-authtool -n client.images --cap mon 'allow r' --cap osd 'allow class-read object_prefix rbd_children, allow rwx pool=images' /etc/ceph/ceph.client.images.keyring
ceph auth add client.images -i /etc/ceph/ceph.client.images.keyring

ceph-authtool --create-keyring /etc/ceph/ceph.client.volumes.keyring
chmod +r /etc/ceph/ceph.client.volumes.keyring
ceph-authtool /etc/ceph/ceph.client.volumes.keyring -n client.volumes --gen-key
ceph-authtool -n client.volumes --cap mon 'allow r' --cap osd 'allow class-read object_prefix rbd_children, allow rwx pool=volumes' /etc/ceph/ceph.client.volumes.keyring
ceph auth add client.volumes -i /etc/ceph/ceph.client.volumes.keyring

#ceph-authtool --create-keyring /etc/ceph/ceph.client.backups.keyring
#chmod +r /etc/ceph/ceph.client.backups.keyring
#ceph-authtool /etc/ceph/ceph.client.backups.keyring -n client.backups --gen-key
#ceph-authtool -n client.backups --cap mon 'allow r' --cap osd 'allow class-read object_prefix rbd_children, allow rwx pool=backups' /etc/ceph/ceph.client.backups.keyring
#ceph auth add client.backups -i /etc/ceph/ceph.client.backups.keyring

echo '[client.images]
keyring = /etc/ceph/ceph.client.images.keyring

[client.volumes]
keyring = /etc/ceph/ceph.client.volumes.keyring' >> /etc/ceph/ceph.conf
#
#[client.backups]
#keyring = /etc/ceph/ceph.client.backups.keyring' >> /etc/ceph/ceph.conf

VMSET="$monnames" vftool.bash run yum -y install rsync
for h in $monnames; do
 rsync -a -e ssh /etc/ceph/ root@$h:/etc/ceph
done

export PATH=$PATH:/mnt/vm-share/vftool
# not sure if this is necessary or not
VMSET="$monnames" vftool.bash run "chmod +r /etc/ceph/ceph.client.admin.keyring"
chmod +r /etc/ceph/ceph.client.admin.keyring

#
VMSET="$monnames" vftool.bash run "service openstack-cinder-scheduler restart;
service openstack-cinder-volume restart;
service openstack-cinder-api restart"

# now kick the tires
#  ceph osd lspools
#  echo test123 > /tmp/test123.txt; rados put test123 /tmp/test123.txt --pool=data
#  rados -p images ls
#  rados -p volumes ls
#  rbd --pool volumes ls

# on a controller node:
#  source /root/keystonerc_admin
# glance -d -v  image-create --name "littlecirros" --is-public true --disk-format qcow2 --container-format bare --file /mnt/vm-share/cirros-0.3.1-x86_64-disk.img
# cinder create --display-name testv1 1
# nova keypair-add testkey > /mnt/vm-share/nova-test.pem
# (after compute is set up)
# nova boot --image littlecirros --flavor m1.tiny  --key_name testkey vm1
# nova attach <nova id> <cinder id> auto

# compute: 
# host group: VMSET=fore4a vftool.bash run '/mnt/vm-share/mcs/foreman/api/hosts.rb set_hostgroup "Compute (Nova Network)" d1a4'
# install: VMSET=c1a4 vftool.bash run ceph-deploy install d1a4
# on the compute node:
# verify /etc/ceph/*
# bash -x /mnt/vm-share/mcs/ceph/libvirt-secret.bash
# service openstack-nova-compute restart
#
# ssh -i /mnt/vm-share/nova-test.pem cirros@10.0.0.4
