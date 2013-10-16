## revert vm's and rerun puppet-class import, seeds.rb on foreman

FOREMAN_NODE=${FOREMAN_NODE:=s14fore1}
# NOTE: the $FOREMAN_NODE will need access to the $MCS_SCRIPTS_DIR dir as well
MCS_SCRIPTS_DIR=${MCS_SCRIPTS_DIR:=/mnt/vm-share/mcs/ha-vms}
VMSET_CHUNK=${VMSET_CHUNK:=s14ha1}
SNAPNAME=${SNAPNAME:=wit_clu_and_mysql_rpms}


VMSET="${VMSET_CHUNK}c1 ${chunk}c2 ${chunk}c3 ${chunk}nfs"

$MCS_SCRIPTS_DIR/reset-vms.bash # this also resets the foreman vm

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
  # notes, hosts assumed as already subscribed to rhel-6-server-rpms and rhel-6-server-optional-rpms
  # ssh root@$vm "yum-config-manager --enable rhel-ha-for-rhel-6-server-rpms"
  # save the step of manually killing puppet so as to run puppet agent by hand...
  ssh root@$vm "killall puppet; killall python" # the horror, the horror.

  # pcs management of shared storage is going to use its own nfs mount options, so no point in below line
  #ssh root@$vm "cat /mnt/vm-share/tmp/fstab-mysql >> /etc/fstab"
done

ssh -t root@$FOREMAN_NODE "bash -x $MCS_SCRIPTS_DIR/foreman-add-hostgroup.bash"

# this is up2date w.r.t. dan's repo already
#ssh root@$FOREMAN_NODE "git clone https://github.com/radez/puppet-pacemaker.git /etc/puppet/environments/production/modules/pacemaker"
