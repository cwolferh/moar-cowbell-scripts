## assuming you have run setup-ha-vms.bash, this is the reset button.
## make sure $SNAPNAME to revert to is correct

# set these 4 variables
export INITIMAGE=${INITIMAGE:=rhel6rdo}
FOREMAN_NODE=${FOREMAN_NODE:=s14fore1}
VMSET_CHUNK=${VMSET_CHUNK:=s14ha1}
SNAPNAME=${SNAPNAME:=wit_clu_and_mysql_rpms}
FOREMAN_SNAPNAME=${SNAPNAME:=$SNAPNAME}

allnodes="${VMSET_CHUNK}c1 ${chunk}c2 ${chunk}c3 ${chunk}nfs $FOREMAN_NODE"
export VMSET="${VMSET_CHUNK}c1 ${chunk}c2 ${chunk}c3 ${chunk}nfs"

which vftool.bash >/dev/null
if [ $? -ne 0 ]; then
  echo 'vftool.bash must be in your PATH' && exit 1
fi

VMSET="$allnodes" vftool.bash stop_guests

# we want the foreman node to be online before the clients are reverted
SNAPNAME=$FOREMAN_SNAPNAME vftool.bash reboot_snap_revert $FOREMAN_NODE

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

# now bring up all the others
SNAPNAME=$SNAPNAME vftool.bash reboot_snap_revert $VMSET
