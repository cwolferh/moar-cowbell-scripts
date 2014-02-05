# Install RDO/Foreman on a VM using vftool.bash.  At a high level:
#   * Install from rpm's
#   * Run latest installer script from source (you need to git clone
#     redhat-openstack/astapor yourself and put it in $install_dir
#     accessible to your foreman vm, i.e. under /mnt/vm-share)
#
# Note 1: You also need to supply your own subscription-manager
# registration script in $secret_rh_registration_script so your vm can
# have access to rhel bits (though many puppet / foreman deps are
# coming through from public repos).
#
# Note 2: This script is entirely dependent on vftool.bash and assumes
# that you have run up to the step "bash -x vftool.bash kick_first_vm"
# in https://github.com/cwolferh/vms-and-foreman/ .  The INITIMAGE
# below must match the value you used.
#
# TODO: add a check mid-script to make sure the correct repos are set
#
# Set these 5 variables
export INITIMAGE=${INITIMAGE:=rhel6rdo}
export FOREMAN_NODE=${FOREMAN_NODE:=fore$( < /dev/urandom tr -dc a-z0-9 | head -c 4 )}
UNATTENDED=${UNATTENDED:=false}
export FROM_SOURCE=${FROM_SOURCE:=true}
POST_INSTALLER_SNAP=${POST_INSTALLER_SNAP:=true}
MCS_SCRIPTS_DIR=${MCS_SCRIPTS_DIR:=/mnt/vm-share/mcs}

provisioning_mode=false
FOREMAN_CLIENT_SCRIPT=${FOREMAN_CLIENT_SCRIPT:=/mnt/vm-share/${FOREMAN_NODE}_foreman_client.sh}

configure_repos_for_rdo=${CONFIGURE_REPOS_FOR_RDO:=false}

# must be visible to $FOREMAN_NODE, so under /mnt/vm-share
secret_rh_registration_script=${REG_SCRIPT:=/mnt/vm-share/tmp/just-subscribe.sh}
# install dir that the FOREMAN_NODE will run the installer from
# (to use the version shipped with the rpm, this would be
#  /usr/share/openstack-foreman-installer/bin)
# install_dir=${INSTALLER_DIR:=/mnt/vm-share/astapor/bin}

# set VMSET for vftool.bash
export VMSET="$FOREMAN_NODE"

wait_for_foreman() {
  port=$1
  ssh_up_cmd="true"
  for vm in $VMSET; do
    ssh_up_cmd="$ssh_up_cmd && nc -w1 -z $vm $port"
  done
  exit_status=1
  while [[ $exit_status -ne 0 ]] ; do
    eval $ssh_up_cmd > /dev/null
    exit_status=$?
    echo -n .
    sleep 2
  done
}

pause_for_investigation() {
  if [ "$UNATTENDED" != "true" ]; then
    echo "PAUSED.  look around, and hit a key to continue"
    read
  fi
}

if [[ ! -f $secret_rh_registration_script  ]]; then
  echo '$secret_rh_registration_script (to register or configure yum repos) must exist'
  exit 1
fi
if [[ ! -f "$MCS_SCRIPTS_DIR/foreman/foreman-run-installer.bash" ]]; then
  echo '$MCS_SCRIPTS_DIR/foreman/foreman-run-installer.bash does not exist'
  echo 'verify $MCS_SCRIPTS_DIR (currently set to ' $MCS_SCRIPTS_DIR ')'
  exit 1
fi
if [[ ! -f vftool.bash  ]]; then
  echo 'vftool.bash needs to be in your current dir (TODO change this :-)'
  exit 1
fi
if [[ ! -f /mnt/vm-share/vftool/vftool.bash  ]]; then
  echo '/mnt/vm-share/vftool/vftool.bash needs to exist (to be accessible by the foreman node)'
  exit 1
fi
bash vftool.bash create_images
bash vftool.bash prep_images
sleep 15  # TODO script to make sure /mnt/$FOREMAN_NODE is unmounted
bash vftool.bash start_guests

while [[ ! -e /mnt/vm-share/$FOREMAN_NODE.hello ]]; do
  echo -n .
  sleep 6
done

bash vftool.bash populate_etc_hosts
bash vftool.bash populate_default_dns

bash vftool.bash stop_guests
bash vftool.bash start_guests

echo "waiting for the sshd on foreman to come up"
wait_for_foreman 22

# subscribe to get your red hat bits
ssh -o 'UserKnownHostsFile /dev/null' -o 'StrictHostKeyChecking no' -t root@$FOREMAN_NODE "bash $secret_rh_registration_script"

mkdir -p /mnt/vm-share/tmp
if [[ ! -e /mnt/vm-share/tmp ]]; then
  echo 'unable to create /mnt/vm-share/tmp'
  exit 1
fi

if [ "$configure_repos_for_rdo" = "true" ]; then
  cat >/mnt/vm-share/tmp/set-rh-repos.bash <<EOF
sed -i 's/enabled = 1/enabled = 0/g' /etc/yum.repos.d/redhat.repo
yum-config-manager --enable rhel-6-server-rpms
yum-config-manager --enable rhel-6-server-optional-rpms
yum clean all
yum repolist

EOF

  ssh -o 'UserKnownHostsFile /dev/null' -o 'StrictHostKeyChecking no' -t root@$FOREMAN_NODE "bash /mnt/vm-share/tmp/set-rh-repos.bash"

  ssh -o 'UserKnownHostsFile /dev/null' -o 'StrictHostKeyChecking no' -t root@$FOREMAN_NODE "rpm --nodigest --quiet -q epel-release || yum -y install http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm"
  ssh -o 'UserKnownHostsFile /dev/null' -o 'StrictHostKeyChecking no' -t root@$FOREMAN_NODE "rpm --nodigest --quiet -q rdo-release-havana-6 || yum install http://repos.fedorapeople.org/repos/openstack/openstack-havana/rdo-release-havana-6.noarch.rpm"
fi

SNAPNAME=pre_foreman_rpms bash vftool.bash reboot_snap_take $FOREMAN_NODE

echo "waiting for the sshd on foreman to come up"
wait_for_foreman 22
#pause_for_investigation

ssh -o 'UserKnownHostsFile /dev/null' -o 'StrictHostKeyChecking no' -t root@$FOREMAN_NODE "yum -y update"
ssh -o 'UserKnownHostsFile /dev/null' -o 'StrictHostKeyChecking no' -t root@$FOREMAN_NODE "yum install -y openstack-foreman-installer augeas"

SNAPNAME=just_the_rpms bash vftool.bash reboot_snap_take $FOREMAN_NODE

echo "waiting for the sshd on foreman to come up"
wait_for_foreman 22
#pause_for_investigation

echo "installing foreman"
REVERT_FROM_SNAP=false \
  bash -x $MCS_SCRIPTS_DIR/foreman/foreman-run-installer.bash
#ssh -o 'UserKnownHostsFile /dev/null' -o 'StrictHostKeyChecking no' -t root@$FOREMAN_NODE "INSTALLER_DIR=$install_dir bash -x /mnt/vm-share/vftool/vftool.bash install_foreman_here $provisioning_mode 2>&1 | tee -a /tmp/$FOREMAN_NODE-install-log"

echo "waiting for the https on foreman to come up"
wait_for_foreman 443
#pause_for_investigation

# TODO: script-check that is safe to restart (probably by looking for
# tail of /tmp/$FOREMAN_NODE-install-log to match known value)
#sleep 900
#pause_for_investigation

# copy the client registration script somewhere handy
VMSET=$FOREMAN_NODE bash vftool.bash run "cp /tmp/foreman_client.sh $FOREMAN_CLIENT_SCRIPT;
chmod ugo+x $FOREMAN_CLIENT_SCRIPT"

if [ "$POST_INSTALLER_SNAP" = "true" ]; then

  if [ "$UNATTENDED" != "true" ]; then
    echo "Foreman is up!  Hit ctrl-c to leave it up, or enter to take another snapshot now"
    read
  fi

  SNAPNAME=post_installer bash vftool.bash reboot_snap_take $FOREMAN_NODE

  echo "waiting for the https on foreman to come up"
  wait_for_foreman 443
fi

echo "You should have foreman installed!  Along with the handy snaps:"
bash vftool.bash snap_list $FOREMAN_NODE
