# Revert foreman to a snap *before* foreman_server.sh was run.
# Then, run foreman_server.sh based on contents from $ASTAPOR
#
FOREMAN_NODE=${FOREMAN_NODE:=s14fore1}
MCS_SCRIPTS_DIR=${MCS_SCRIPTS_DIR:=/mnt/vm-share/mcs/ha-vms}
VMSET_CHUNK=${VMSET_CHUNK:=s14ha1}
# The name of the snap with the assumption that this snap has the rpms
# openstack-foreman-installer and augeas installed, but
# foreman_server.sh has not been run yet.
FOREMAN_SNAPNAME=${FOREMAN_SNAPNAME:=just_the_rpms}
DUMP_ASTAPOR_OUTPUT=${DUMP_ASTAPOR_OUTPUT:=true}

provisioning_mode=false

SNAPNAME=$FOREMAN_SNAPNAME vftool.bash reboot_snap_revert $FOREMAN_NODE

test_https="nc -w1 -z $FOREMAN_NODE 22"
echo "waiting for ssh on $FOREMAN_NODE to come up"
sleep 10
exit_status=1
while [[ $exit_status -ne 0 ]] ; do
  eval $test_https > /dev/null
  exit_status=$?
  echo -n .
  sleep 2
done

echo "prep foreman-server"
ssh -o 'UserKnownHostsFile /dev/null' -o 'StrictHostKeyChecking no' \
    root@$FOREMAN_NODE "bash -x $MCS_SCRIPTS_DIR/prep-foreman-server.bash"

echo "running foreman_server.sh"
ssh -o 'UserKnownHostsFile /dev/null' -o 'StrictHostKeyChecking no' -t \
    root@$FOREMAN_NODE "bash -x /mnt/vm-share/vftool/vftool.bash install_foreman_here $provisioning_mode >/tmp/$FOREMAN_NODE-install-log 2>&1"

if [ $DUMP_ASTAPOR_OUTPUT = "true" ]; then
  ssh -o 'UserKnownHostsFile /dev/null' -o 'StrictHostKeyChecking no' root@$FOREMAN_NODE 'cat /tmp/$FOREMAN_NODE-install-log'
fi

