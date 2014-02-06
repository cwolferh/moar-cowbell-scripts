usage(){
  echo "Usage: "
  echo "   VMSET_CHUNK=uniqueClientChunk new-foreman-clients.bash N"
  echo "     (where N is number of new clients to register to foreman)"
  echo
  echo "  or just"
  echo
  echo "    VMSET='myclientfoo myclientbar' new-foreman-clients.bash"
  exit 1
}

# set these 5 variables
export INITIMAGE=${INITIMAGE:=rhel6rdo}
FOREMAN_NODE=${FOREMAN_NODE:=s14fore1}

#VMSET_CHUNK=${VMSET_CHUNK:=s14ha2}

# you may want to hold off on foreman_client.sh registration for later
# (especially if you are going to be in the habit of reverting
#  foreman to a pre-foreman_server.sh state as part of testing),
# in which case set this to true
SKIP_FOREMAN_CLIENT_REGISTRATION=${SKIP_FOREMAN_CLIENT_REGISTRATION:=false}

# This client script must exist (if above var is true) before running
# this script.  For now, cp it from /tmp on your foreman server to
# your chosen location/name, will automate more in future
FOREMAN_CLIENT_SCRIPT=${FOREMAN_CLIENT_SCRIPT:=/mnt/vm-share/${FOREMAN_NODE}_foreman_client.sh}
SKIPSNAP=${SKIPSNAP:=false}
SNAPNAME=${SNAPNAME:=new_foreman_cli}


# if false, wait for user input to continue after key steps.
UNATTENDED=${UNATTENDED:=false}

# if you want to run a script that registers and configures your rhel
# repos, this is the place to reference that script.  otherwise, leave
# blank.
REG_SCRIPT=${REG_SCRIPT:=''}

if [ "x$VMSET" = "x" -a "x${VMSET_CHUNK}" = "x" ]; then
  echo 'You must define $VMSET or $VMSET_CHUNK'; usage
fi
if [ "x$VMSET" != "x" -a "x${VMSET_CHUNK}" != "x" ]; then
  echo 'You must not define both $VMSET and $VMSET_CHUNK'; usage
fi

[ "x${VMSET_CHUNK}" != "x" -a "$#" -ne 1 ] && usage

if [ "x${VMSET_CHUNK}" != "x" ]; then
  numclis=$1
  
  vmset="${VMSET_CHUNK}1"
  
  i=2
  while [ $i -le $numclis ]; do
    vm="$VMSET_CHUNK$i"
    vmset="$vmset $vm"
    i=$[$i+1]
  done
  
  export VMSET=$vmset
fi

for vm in $VMSET; do
  sudo virsh domstate $vm >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "$vm already exists.  Exiting."
    exit 1
  fi
done

SETUP_COMMANDS="create_images prep_images start_guests"

for setup_command in $SETUP_COMMANDS; do
  echo "running bash vftool.bash $setup_command"
  vftool.bash $setup_command
  if [ "$UNATTENDED" = "false" ]; then
    echo "press enter to continue"
    read
  fi
done
echo "waiting for all hosts to write their /mnt/vm-share/<vmname>.hello files"
# this needs to happen so populate_etc_hosts can succeed
all_hosts_seen=1
while [[ $all_hosts_seen -ne 0 ]] ; do
  all_hosts_seen=0
  for vm in $VMSET; do
    if [[ ! -e /mnt/vm-share/$vm.hello ]]; then
      all_hosts_seen=1
    fi
  done
  sleep 6
  echo -n .
done

vftool.bash populate_etc_hosts
vftool.bash populate_default_dns
if [ "$UNATTENDED" = "false" ]; then
  echo 'press enter when the network is back up'
  read
else
  sleep 10
fi

# restarting the network means need to restart the guests (tragically)
vftool.bash stop_guests

if [ "$UNATTENDED" = "false" ]; then
  echo 'press enter when the guests have stopped'
  read
else
  sleep 10
fi

vftool.bash first_snaps
vftool.bash start_guests
vftool.bash wait_for_port 22

if [ "$UNATTENDED" = "false" ]; then
  echo 'verify the hosts are up and reachable by ssh'
  read
fi

if [ "x$REG_SCRIPT" != "x" ]; then
  vftool.bash run "bash ${REG_SCRIPT}"
fi

# chances are we will want augeas and puppet
vftool.bash run "yum -y install augeas puppet"

SNAPNAME=pre_foreman_cli vftool.bash reboot_snap_take $VMSET
vftool.bash wait_for_port 22

# populating dns restarts the network, so need to restart the foreman server
if [ "$SKIP_FOREMAN_CLIENT_REGISTRATION" = "false" ]; then
  vftool.bash stop_guests $FOREMAN_NODE
  vftool.bash start_guests $FOREMAN_NODE

  if [ "$UNATTENDED" = "false" ]; then
    echo 'press a key to continue when the foreman web UI is up'
    read
  else
    VMSET="$FOREMAN_NODE" vftool.bash wait_for_port 443
  fi
  vftool.bash run "bash ${FOREMAN_CLIENT_SCRIPT}"
fi

if [ "$SKIPSNAP" != "true" ]; then
  if [ "$SKIP_FOREMAN_CLIENT_REGISTRATION" = "false" ]; then
    SNAPNAME=$SNAPNAME bash vftool.bash reboot_snap_take $VMSET $FOREMAN_NODE
  else
    SNAPNAME=$SNAPNAME bash vftool.bash reboot_snap_take $VMSET
  fi
fi
