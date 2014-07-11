# Revert foreman to a snap *before* foreman_server.sh was run.
# Then, run foreman_server.sh based on contents from $ASTAPOR
#
FOREMAN_NODE=${FOREMAN_NODE:=s14fore1}
MCS_SCRIPTS_DIR=${MCS_SCRIPTS_DIR:=/mnt/vm-share/mcs}
# The name of the snap with the assumption that this snap has the rpms
# openstack-foreman-installer and augeas installed, but
# foreman_server.sh has not been run yet.
FOREMAN_SNAPNAME=${FOREMAN_SNAPNAME:=just_the_rpms}
DUMP_ASTAPOR_OUTPUT=${DUMP_ASTAPOR_OUTPUT:=true}
FROM_SOURCE=${FROM_SOURCE:=true}
REVERT_FROM_SNAP=${REVERT_FROM_SNAP:=true}

PROVISIONING_MODE=${PROVISIONING_MODE:=false}
# only applicable for provisioning mode
INSTALLURL=${INSTALLURL:=http://yourrhel6mirror.com/somepath/os/x86_64/}

FOREMAN_POST_INSTALL_SCRIPT=${FOREMAN_POST_INSTALL_SCRIPT:=/bin/true}

if [ "$REVERT_FROM_SNAP" = "true" ]; then
  SNAPNAME=$FOREMAN_SNAPNAME vftool.bash reboot_snap_revert $FOREMAN_NODE
fi

# Try setting this to true if you get an error like
# "[Errno 256] No more mirrors to try" in the installer's yum updates
# YUM_REFRESH=${YUM_REFRESH:=false}

VMSET=$FOREMAN_NODE vftool.bash wait_for_port 22

# this hack is probably not necessary most of the time
#if [ "$YUM_REFRESH" = "true" ]; then
#  ssh -o 'UserKnownHostsFile /dev/null' -o 'StrictHostKeyChecking no' \
#    root@$FOREMAN_NODE "yum clean all; yum repolist"
#fi

echo "prep foreman-server"
VMSET=$FOREMAN_NODE vftool.bash run "FROM_SOURCE=${FROM_SOURCE} bash -x $MCS_SCRIPTS_DIR/foreman/prep-foreman-server.bash"

echo "running foreman_server.sh"
if [ $DUMP_ASTAPOR_OUTPUT = "true" ]; then
  cmdsuffix='2>&1 | tee -a /tmp/'$FOREMAN_NODE-install-log
  #ssh -o 'UserKnownHostsFile /dev/null' -o 'StrictHostKeyChecking no' root@$FOREMAN_NODE "cat /tmp/$FOREMAN_NODE-install-log"
else
  cmdsuffix='>/tmp/'$FOREMAN_NODE'-install-log 2>&1'
fi
VMSET=$FOREMAN_NODE vftool.bash run "INSTALLURL=$INSTALLURL bash -x /mnt/vm-share/vftool/vftool.bash install_foreman_here $PROVISIONING_MODE $cmdsuffix"

VMSET=$FOREMAN_NODE vftool.bash run $FOREMAN_POST_INSTALL_SCRIPT
