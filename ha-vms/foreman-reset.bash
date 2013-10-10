## just revert the foreman vm, and re-import puppet

foreman_node='s6fore1'
# NOTE: the $foreman_node will need access to the $scripts_home dir as well
scripts_home=/mnt/vm-share/moar-cowbell-scripts/ha-vms
chunk='s6ha1' # the common vm prefix
snapname=wit_clu_and_mysql_rpms
#snapname=ready_for_mysql2

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

ssh -t root@$foreman_node "bash -x $scripts_home/foreman-add-hostgroup.bash"

# this is up2date w.r.t. dan's repo already
#ssh root@$foreman_node "git clone https://github.com/radez/puppet-pacemaker.git /etc/puppet/environments/production/modules/pacemaker"
