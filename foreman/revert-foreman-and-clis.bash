## revert foreman to state before foreman_server.sh is run
## revert other hosts as well
## optionally register them to foreman


export FOREMAN_NODE=${FOREMAN_NODE:=s14fore1}
# NOTE: the $FOREMAN_NODE will need access to the $MCS_SCRIPTS_DIR dir as well
export MCS_SCRIPTS_DIR=${MCS_SCRIPTS_DIR:=/mnt/vm-share/mcs}
# snapnames we revert all other guests too (should be pre-foreman-cli
# registration)
export SNAPNAME=${SNAPNAME:=new_foreman_cli}
# snapname we revert to where we re-run foreman_server.sh
export FOREMAN_SNAPNAME=${FOREMAN_SNAPNAME:=just_the_rpms}
export FROM_SOURCE=${FROM_SOURCE:=true}
UNATTENDED=${UNATTENDED:=false}
export VMSET_TO_REVERT=${VMSET_TO_REVERT:="gluc1 gluc2"}
# below might be a subset of above if a vm does not need to register
# to foreman (e.g. an nfs server)
export VMSET_TO_REGISTER=${VMSET_TO_REGISTER:=$VMSET_TO_REVERT}

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
  bash -x $MCS_SCRIPTS_DIR/foreman/foreman-run-installer.bash
  pause_for_investigation
fi

#VMSET="${VMSET_CHUNK}c1 ${VMSET_CHUNK}c2 ${VMSET_CHUNK}c3 ${VMSET_CHUNK}nfs" 
VMSET=$VMSET_TO_REVERT
echo "reverting all other nodes: $VMSET"
SNAPNAME=$SNAPNAME bash vftool.bash reboot_snap_revert $VMSET
pause_for_investigation

echo "waiting for hosts to boot"
VMSET="$VMSET_TO_REVERT" vftool.bash wait_for_port 22
echo "waiting for webserver on $FOREMAN_NODE to come up"
VMSET="$FOREMAN_NODE" vftool.bash wait_for_port 443

if [ "$SKIP_FOREMAN_CLIENT_REGISTRATION" != "true" ]; then
  #VMSET="${VMSET_CHUNK}c1 ${VMSET_CHUNK}c2 ${VMSET_CHUNK}c3"
  VMSET=$VMSET_TO_REGISTER vftool.bash run \
     "bash ${FOREMAN_CLIENT_SCRIPT} && /etc/init.d/puppet stop &" 
fi
