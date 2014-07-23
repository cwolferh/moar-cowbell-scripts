#!/bin/bash
#
# Note there some interactive prompts in this script, so be prepared
# to respond to those.
#
# This should set up node with a ceph mon and a single 1.5GB osd
# 

ice_tarball=/mnt/vm-share/ice12/ICE-1.2-rhel7.tar.gz
icedir=/mnt/vm-share/ice-work
nodename=c1a4

setup_ice_repo() {
  mkdir -p $icedir
  cd $icedir
  tar -zxvf $ice_tarball -C $icedir
  python $icedir/ice_setup.py
}

setup_ice_repo
cd $icedir

calamari-ctl initialize

ceph-deploy new $nodename
echo 'osd pool default size = 1' >> ceph.conf 
echo 'osd journal size = 1500' >> ceph.conf 

ceph-deploy install $nodename
ceph-deploy mon create-initial
ceph-deploy mon create $nodename
ceph-deploy gatherkeys $nodename

mkdir /osd0
ceph-deploy osd prepare $nodename:/osd0
ceph-deploy osd activate $nodename:/osd0
ceph-deploy mds create $nodename

# now kick the tires
#  ceph osd lspools
#  echo test123 > /tmp/test123.txt; rados put test123 /tmp/test123.txt --pool=data
#  rados -p data ls
