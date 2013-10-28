## just revert the foreman vm, and re-import puppet
## (assumes foreman_server.sh has already been run and does not rerun it)

FOREMAN_NODE=${FOREMAN_NODE:=s14fore1}
# NOTE: the $FOREMAN_NODE will need access to the $MCS_SCRIPTS_DIR dir as well
MCS_SCRIPTS_DIR=${MCS_SCRIPTS_DIR:=/mnt/vm-share/mcs}
VMSET_CHUNK=${VMSET_CHUNK:=s14ha1}
SNAPNAME=${SNAPNAME:=wit_clu_and_mysql_rpms}
#SNAPNAME=${SNAPNAME:=wit_clu_and_mysql_rpms}

# we want the foreman node to be online before the clients are reverted
SNAPNAME=$SNAPNAME vftool.bash reboot_snap_revert $FOREMAN_NODE

test_https="nc -w1 -z $FOREMAN_NODE 443"
echo "waiting for the https on $FOREMAN_NODE to come up"
sleep 10
exit_status=1
while [[ $exit_status -ne 0 ]] ; do
  eval $test_https > /dev/null
  exit_status=$?
  echo -n .
  sleep 2
done

ssh -t root@$FOREMAN_NODE "bash -x $MCS_SCRIPTS_DIR/ha-vms/foreman-add-hostgroup.bash"

# this is up2date w.r.t. dan's repo already
#ssh root@$FOREMAN_NODE "git clone https://github.com/radez/puppet-pacemaker.git /etc/puppet/environments/production/modules/pacemaker"
