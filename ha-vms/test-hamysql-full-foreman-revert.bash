## revert foreman to state before foreman_server.sh is run
## revert other hosts as well

# TODO: replace with a wrapper of ../foreman/revert-foreman-and-clis.bash

export FOREMAN_NODE=${FOREMAN_NODE:=s14fore1}
# NOTE: the $FOREMAN_NODE will need access to the $MCS_SCRIPTS_DIR dir as well
export MCS_SCRIPTS_DIR=${MCS_SCRIPTS_DIR:=/mnt/vm-share/mcs}
VMSET_CHUNK=${VMSET_CHUNK:=s14ha1}
# snapnames we revert all other guests too (should be pre-foreman-cli
# registration)
export SNAPNAME=${SNAPNAME:=new_foreman_cli}
# snapname we revert to where we re-run foreman_server.sh
export FOREMAN_SNAPNAME=${FOREMAN_SNAPNAME:=just_the_rpms}
UNATTENDED=${UNATTENDED:=false}

# may want to do this if ha hosts not yet subscribed to a running
# foreman install
SKIP_FOREMAN_RUN_INSTALLER=${SKIP_FOREMAN_RUN_INSTALLER:=false}
SKIP_FOREMAN_CLIENT_REGISTRATION=${SKIP_FOREMAN_CLIENT_REGISTRATION:=false}
FOREMAN_CLIENT_SCRIPT=${FOREMAN_CLIENT_SCRIPT:=/mnt/vm-share/rdo/${FOREMAN_NODE}_foreman_client.sh}

pause_for_investigation() {
  if [ "$UNATTENDED" != "true" ]; then
    echo "PAUSED.  look around, and hit a key to continue"
    read
  fi
}

if [ "$SKIP_FOREMAN_RUN_INSTALLER" != "true" ]; then
  echo "reverting foreman node: $FOREMAN_NODE"
  bash -x $MCS_SCRIPTS_DIR/ha-vms/foreman-run-installer.bash
  pause_for_investigation
fi

VMSET="${VMSET_CHUNK}c1 ${VMSET_CHUNK}c2 ${VMSET_CHUNK}c3 ${VMSET_CHUNK}nfs" 
echo "reverting all other nodes: $VMSET"
SNAPNAME=$SNAPNAME bash -x vftool.bash reboot_snap_revert $VMSET
pause_for_investigation

echo "waiting for the https on foreman to come up"
est_https="nc -w1 -z $FOREMAN_NODE 443"
exit_status=1
while [[ $exit_status -ne 0 ]] ; do
  eval $test_https > /dev/null
  exit_status=$?
  echo -n .
  sleep 6
done

ssh_up_cmd="true"
for vm in $VMSET; do
  ssh_up_cmd="$ssh_up_cmd && nc -w1 -z $vm 22"
done
echo "waiting for the sshd on hosts { $VMSET } to come up"
exit_status=1
while [[ $exit_status -ne 0 ]] ; do
  eval $ssh_up_cmd > /dev/null
  exit_status=$?
  sleep 6
  echo -n .
done

if [ "$SKIP_FOREMAN_CLIENT_REGISTRATION" != "true" ]; then
  VMSET="${VMSET_CHUNK}c1 ${VMSET_CHUNK}c2 ${VMSET_CHUNK}c3"
  for vm in $VMSET; do
    #  hosts assumed as already subscribed to rhel-6-server-rpms
    # and rhel-6-server-optional-rpms
    #ssh root@$vm  -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" \
    #  "yum-config-manager --enable rhel-ha-for-rhel-6-server-rpms"
  
    ssh root@$vm -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" \
     "bash ${FOREMAN_CLIENT_SCRIPT} &" 

    # pcs management of shared storage is going to use its own nfs mount options, so no point in below line
    #ssh root@$vm "cat /mnt/vm-share/tmp/fstab-mysql >> /etc/fstab"
  done

  for vm in $VMSET; do
    # save the step of manually killing puppet so as to run puppet agent by hand...
    ssh root@$vm -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" \
      "killall puppet; killall python" # the horror, the horror.
  done  
fi
