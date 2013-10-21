#!/bin/bash

# install, mysql and cluster rpm's for faster testing
# and re-snap

NEW_SNAPNAME=${SNAPNAME:=wit_clu_and_mysql_rpms}
FOREMAN_NODE=${FOREMAN_NODE:=s14fore1}
# NOTE: the $FOREMAN_NODE will need access to the $MCS_SCRIPTS_DIR dir as well
MCS_SCRIPTS_DIR=${MCS_SCRIPTS_DIR:=/mnt/vm-share/mcs/ha-vms}
VMSET_CHUNK=${VMSET_CHUNK:=s14ha1}

VMSET="${VMSET_CHUNK}c1 ${chunk}c2 ${chunk}c3 ${chunk}nfs"

$MCS_SCRIPTS_DIR/reset-vms.bash

ssh_up_cmd="true"
for vm in $VMSET; do
  ssh_up_cmd="$ssh_up_cmd && nc -w1 -z $vm 22"
done
echo "waiting for the sshd on hosts { $VMSET } to come up"
sleep 15
exit_status=1
while [[ $exit_status -ne 0 ]] ; do
  eval $ssh_up_cmd > /dev/null
  exit_status=$?
  echo -n .
  sleep 2
done

VMSET="${VMSET_CHUNK}c1 ${chunk}c2 ${chunk}c3"

for vm in $VMSET; do
  ssh root@$vm "yum-config-manager --enable rhel-ha-for-rhel-6-server-rpms"
  ssh root@$vm "cp /mnt/vm-share/tmp/clusterlabs.repo /etc/yum.repos.d"
  ssh root@$vm "yum -y install cman pacemaker mysql-server ccs MySQL-python pcs"
done

SNAPNAME=$NEW_SNAPNAME vftool.bash reboot_snap_take $VMSET
