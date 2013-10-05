## assuming you have run setup-ha-vms.bash, this is the reset button.
## make sure $snapname to revert to is correct

# set these 4 variables
export INITIMAGE=rhel6rdo
foreman_node='s6fore1'
chunk='s6ha1'
#snapname=ready_for_mysql2
snapname=wit_clu_and_mysql_rpms

export VMSET="${chunk}c1 ${chunk}c2 ${chunk}c3 ${chunk}nfs"

which vftool.bash >/dev/null
if [ $? -ne 0 ]; then
  echo 'vftool.bash must be in your PATH' && exit 1
fi

vftool.bash stop_guests

# we want the foreman node to be online before the clients are reverted
SNAPNAME=$snapname vftool.bash reboot_snap_revert $foreman_node

test_https="nc -w1 -z $foreman_node 443"
echo "waiting for the https on $foreman_node to come up"
sleep 10
exit_status=1
while [[ $exit_status -ne 0 ]] ; do
  eval $test_https > /dev/null
  exit_status=$?
  echo -n .
  sleep 2
done

# now bring up all the others
SNAPNAME=$snapname vftool.bash reboot_snap_revert $VMSET
