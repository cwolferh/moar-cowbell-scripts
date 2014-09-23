#!/bin/bash
#
# This script is run from a node that doubles as both a ceph installer
# and storage node.  It installs ceph mons on the $monnames given
# existing ceph config files and sets up a osd volume.  Make sure
# ceph.conf includes "osd_pool_default_size = 1".
#
# Typical order of operations:
#  * make sure the 3 ha controller nodes/mons have not run puppet yet.
#     (i.e., they are not yet configured as ha controllers,
#      just a fresh OS)
#  * prep this host to be enable ssh to the mons/compute ( see
#     bm-simple-server-prep.bash )
#  * run this script *on the $osdnodename vm*
#
# The BIG ASSUMPTION
#  * ceph.client.volumes.keyring, ceph.client.images.keyring and ceph.conf
#    already exist (i.e., thanks to staypuft)
#  * For now, ceph.mon.keyring needs to exist too but won't be needed
#    when http://tracker.ceph.com/issues/9510 lands.

nodenames="c1a1 c1a2 c1a3 c1a4"
#monnames="c1a1 c1a2 c1a3"
monnames_to_ips="c1a1:192.168.200.10 c1a2:192.168.200.20 c1a3:192.168.200.30"
firstmon=c1a1
#nodenames="c1a1 c1a4"
#monnames="c1a1"
osdnodename=c1a4
computenodes=d1a4
cephconf=/mnt/vm-share/tmp/ceph.conf
workdir=/root

export PATH=$PATH:/mnt/vm-share/vftool
VMSET=$nodenames vftool.bash run "cp /mnt/vm-share/ceph-firefly.repo /etc/yum.repos.d/ceph-firefly.repo"
yum -y install ceph-deploy

cd $workdir

cp /mnt/vm-share/tmp/ceph.conf $workdir/ceph.conf
chmod ugo-wx $workdir/ceph.conf
cp /mnt/vm-share/tmp/ceph.client.volumes.keyring $workdir/ceph.client.volumes.keyring
cp /mnt/vm-share/tmp/ceph.client.images.keyring $workdir/ceph.client.images.keyring
cp /mnt/vm-share/tmp/ceph.mon.keyring $workdir/ceph.mon.keyring
mkdir -p /etc/ceph/
cp -r $workdir/ceph.* /etc/ceph/

ceph-deploy --ceph-conf $cephconf install $nodenames
echo 'HIT A KEY TO CONTINUE'; read

#####################
## BEGIN ALTERNATIVE TO ceph-deploy mon create-initial ##

ceph-deploy mon create $monnames_to_ips
echo 'HIT A KEY TO CONTINUE'; read

ssh $firstmon 'while ! eval "ceph -s"; do sleep 5; echo .; done'
rsync -a -e ssh root@$firstmon:/etc/ceph/ceph.client.admin.keyring /etc/ceph/
echo 'HIT A KEY TO CONTINUE'; read

ceph-deploy gatherkeys $firstmon
echo 'HIT A KEY TO CONTINUE'; read

ceph-deploy gatherkeys $osdnodename
echo 'HIT A KEY TO CONTINUE'; read

### END ALTERNATIVE TO ceph-deploy mon create-initial ##
#####################

mkdir /osd0
# need to specify overwrite since files are not identical bit-wise (but they are functionally identical)
ceph-deploy --overwrite-conf osd prepare $osdnodename:/osd0
ceph-deploy osd activate $osdnodename:/osd0
ceph-deploy mds create $osdnodename

# creating backups though may not be necessary if cinder-backup
# service not running

ceph osd pool create images 128
ceph osd pool create volumes 128
#ceph osd pool create backups 128

ceph auth import -i /etc/ceph/ceph.client.images.keyring
ceph auth import -i /etc/ceph/ceph.client.volumes.keyring

# this is needed so that compute nodes may execute
#   ceph auth get-key client.volumes
#   More context:
#     Quickstack::Compute_common/Exec[set-secret-value virsh]
#     /usr/bin/virsh secret-set-value --secret $(cat /etc/nova/virsh.secret) --base64 $(ceph auth get-key client.volumes)
ceph-deploy --overwrite-conf admin $computenodes

# now kick the tires
#  ceph osd lspools
#  echo test123 > /tmp/test123.txt; rados put test123 /tmp/test123.txt --pool=data
#  rados -p images ls
#  rados -p volumes ls
#  rbd --pool volumes ls

# on a controller node:
#  source /root/keystonerc_admin
# glance -d -v  image-create --name "littlecirros" --is-public true --disk-format qcow2 --container-format bare --file /mnt/vm-share/cirros-0.3.2-x86_64-disk.img
# cinder create --display-name testv1 1
# nova keypair-add testkey >/mnt/vm-share/nova-test.pem
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
