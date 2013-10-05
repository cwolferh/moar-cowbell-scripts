#!/bin/bash

# install, mysql and cluster rpm's for faster testing
# and re-snap

new_snapname=wit_clu_and_mysql_rpms
foreman_node='s6fore1.example.com'
# NOTE: the $foreman_node will need access to the $scripts_home dir as well
scripts_home=/mnt/vm-share/moar-cowbell-scripts/ha-vms
chunk='s6ha1' # the common vm prefix

VMSET="${chunk}c1 ${chunk}c2 ${chunk}c3 ${chunk}nfs"

$scripts_home/reset-vms.bash

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

VMSET="${chunk}c1 ${chunk}c2 ${chunk}c3"

for vm in $VMSET; do
  ssh root@$vm "yum-config-manager --enable rhel-ha-for-rhel-6-server-rpms"
  ssh root@$vm "cp /mnt/vm-share/tmp/clusterlabs.repo /etc/yum.repos.d"
  ssh root@$vm "yum -y install cman pacemaker mysql-server ccs MySQL-python pcs"
done

SNAPNAME=$new_snapname vftool.bash reboot_snap_take $VMSET
