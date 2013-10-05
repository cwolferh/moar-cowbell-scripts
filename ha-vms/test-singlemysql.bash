mode=test
snapname=wit_clu_and_mysql_rpms 
foreman_node=s6fore1
scripts_home=/mnt/vm-share/moar-cowbell-scripts/ha-vms
export VMSET=s6singlemysql
#bash -x /mnt/pub/rdo/ha/reset-vms.bash

echo $VMSET
###############################################################################
## SETUP 
if [ "$mode" = "setup" ]; then
  export INITIMAGE=rhel6rdo
  bash -x vftool.bash create_images
  bash -x vftool.bash prep_images
  bash -x vftool.bash start_guests
  bash -x vftool.bash populate_etc_hosts
  bash -x vftool.bash populate_default_dns
  
  echo 'press a key when the network is back up'
  read
  
  sudo virsh destroy $foreman_node
  sudo virsh start $foreman_node
  
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
  
  for domname in $VMSET; do
    ## XXXXXXXXXXXXXXX enter ther name of your client script below
    sudo ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" $domname "yum -y install augeas"
    sudo ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" $domname "bash /mnt/vm-share/rdo/s6fore1_foreman_client.sh"
  done
  
  SNAPNAME=new_foreman_cli bash -x vftool.bash reboot_snap_take $VMSET
  # 
  # echo SNAPNAME=wit_clu_and_mysql_rpms bash -x vftool.bash reboot_snap_take $VMSET foreman
fi

###############################################################################
## TEST 
if [ "$mode" = "test" ]; then
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

  SNAPNAME=$snapname vftool.bash reboot_snap_revert $VMSET

  ssh -t root@$foreman_node "bash -x $scripts_home/foreman-add-hostgroup.bash"
  
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

fi