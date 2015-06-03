#!/bin/bash
#
# Works with ceph-1.3 beta
#  * needed to create admin keyring and add it to mon keyring,
#    this was not necessary before
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

nodenames="d1a1 d1a2 d1a3 d1a4"
#monnames="d1a1 d1a2 d1a3"
monnames_to_ips="d1a1:192.168.111.110 d1a2:192.168.111.120 d1a3:192.168.111.130"
#monnames_to_ips="e1a1:192.168.200.110 e1a2:192.168.200.120 e1a3:192.168.200.130"
firstmon=d1a1
#nodenames="d1a1 d1a4"
#monnames="d1a1"
osdnodename=d1a4
computenodes=d1a5
cephconf=/mnt/vm-share/tmp/ceph.conf
workdir=/root

export PATH=$PATH:/mnt/vm-share/vftool

maybe_pause() {
   echo 'HIT A KEY TO CONTINUE'; read  
  #/bin/true
}

# ok for rhel 7.0
# https://gist.githubusercontent.com/cwolferh/da15f47b2659173b84fe/raw/6069e0760a95dbf54715eb67f6a2ef168312448e/ceph-firefly.repo
#VMSET=$nodenames vftool.bash run "cp /mnt/vm-share/ceph-firefly.repo /etc/yum.repos.d/ceph-firefly.repo"

# need a newer ceph repo for 7.1
#VMSET=$nodenames vftool.bash run "cp /mnt/vm-share/ceph-122.repo /etc/yum.repos.d/ceph-122.repo"
yum -y install ceph-deploy ceph-common

cd $workdir

prod_workflow=true
if [ "$prod_workflow" = 'true' ]; then

  # assume the following already exists (e.g., because this is the storage
  # node and the puppet agent has run and created the files):
  #   /etc/ceph/ceph.conf, 
  #   /etc/ceph/ceph.client.volumes.keyring
  #   /etc/ceph/ceph.client.images.keyring

  # ceph-deploy still needs a ceph.mon.keyring, so create on
  echo '[mon.]' >/etc/ceph/ceph.mon.keyring
  echo "key = `ceph-authtool --gen-print-key`" >>/etc/ceph/ceph.mon.keyring
  echo 'caps mon = allow *' >>/etc/ceph/ceph.mon.keyring

  ceph-authtool --create-keyring /etc/ceph/ceph.client.admin.keyring --gen-key -n client.admin --set-uid=0 --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow'
  ceph-authtool /etc/ceph/ceph.mon.keyring --import-keyring /etc/ceph/ceph.client.admin.keyring

  cp /etc/ceph/ceph.* $workdir

else

  # development workflow -- this probably won't work unless you
  # add mon and admin keyrings
  cp /mnt/vm-share/tmp/ceph.conf $workdir/ceph.conf
  chmod ugo-wx $workdir/ceph.conf
  cp /mnt/vm-share/tmp/ceph.client.volumes.keyring $workdir/ceph.client.volumes.keyring
  cp /mnt/vm-share/tmp/ceph.client.images.keyring $workdir/ceph.client.images.keyring
  cp /mnt/vm-share/tmp/ceph.mon.keyring $workdir/ceph.mon.keyring
  mkdir -p /etc/ceph/
  cp -r $workdir/ceph.* /etc/ceph/
 
fi
maybe_pause

ceph-deploy --ceph-conf $cephconf install $nodenames $computenodes
maybe_pause

# cheat
for m in d1a1 d1a2 d1a3; do
  rsync -a -e ssh /etc/ceph/ceph.mon.keyring $m:/etc/ceph/ceph.mon.keyring
  rsync -a -e ssh /etc/ceph/ceph.client.admin.keyring $m:/etc/ceph/ceph.client.admin.keyring
done
maybe_pause

ceph-deploy --overwrite-conf mon create $monnames_to_ips
maybe_pause

ceph-deploy gatherkeys $firstmon
maybe_pause

ceph-deploy gatherkeys $osdnodename
maybe_pause

mkdir /osd0
ceph-deploy --overwrite-conf osd prepare $osdnodename:/osd0
ceph-deploy osd activate $osdnodename:/osd0

# creating backups though may not be necessary if cinder-backup
# service not running

ceph osd pool create images 128
ceph osd pool create volumes 128
#ceph osd pool create backups 128

# development values!  these would be cray-cray in production
ceph osd pool set data size 1
ceph osd pool set metadata size 1
ceph osd pool set rbd size 1
ceph osd pool set images size 1
ceph osd pool set volumes size 1

mkdir /osd1
ceph-deploy --overwrite-conf osd prepare $osdnodename:/osd1
ceph-deploy osd activate $osdnodename:/osd1
mkdir /osd2
ceph-deploy --overwrite-conf osd prepare $osdnodename:/osd2
ceph-deploy osd activate $osdnodename:/osd2


ceph auth import -i /etc/ceph/ceph.client.images.keyring
ceph auth import -i /etc/ceph/ceph.client.volumes.keyring

# this is needed so that compute nodes may execute
#   ceph auth get-key client.volumes
#   More context:
#     Quickstack::Compute_common/Exec[set-secret-value virsh]
#     /usr/bin/virsh secret-set-value --secret $(cat /etc/nova/virsh.secret) --base64 $(ceph auth get-key client.volumes)
# Note, you may need to create /etc/ceph/ on the the compute node
#ceph-deploy --overwrite-conf admin $computenodes

# now kick the tires
#  ceph osd lspools
#  echo test123 > /tmp/test123.txt; rados put test123 /tmp/test123.txt --pool=data
#  rados -p images ls
#  rados -p volumes ls
#  rbd --pool volumes ls

# on a controller node:
#  source /root/keystonerc_admin
# glance -d -v  image-create --name "littlecirros" --is-public true --disk-format qcow2 --container-format bare --file /mnt/vm-share/cirros-0.3.3-x86_64-disk.img
# cinder create --display-name testv1 1
# nova keypair-add testkey >/mnt/vm-share/nova-test.pem; chmod go-rw /mnt/vm-share/nova-test.pem
# (after compute is set up)
# nova boot --image littlecirros --flavor m1.tiny  --key_name testkey vm1
# nova volume-attach <nova id> <cinder id> auto

# compute:
# host group: VMSET=fore4a vftool.bash run '/mnt/vm-share/mcs/foreman/api/hosts.rb set_hostgroup "Compute (Nova Network)" d1a4'
# install: VMSET=d1a5 vftool.bash run ceph-deploy install d1a4
# on the compute node:
# verify /etc/ceph/*
#
# ssh -i /mnt/vm-share/nova-test.pem cirros@10.0.0.4
