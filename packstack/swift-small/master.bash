#!/bin/bash

#
# create 3 swift storage nodes, 1 proxy using packstack.
# that's it.

export VMSET_CHUNK=${VMSET_CHUNK:=sw1a}
export NUMHOSTS=${NUMHOSTS:=4}
export INITIMAGE=${INITIMAGE:=beta40nov15}
export UNATTENDED=${UNATTENDED:=true}

export MCS_SCRIPTS_DIR=${MCS_SCRIPTS_DIR:=$( cd "$(dirname "$0")"/../.. ; pwd -P )}

export PRE_PACK_SNAPNAME=prepack
## 

if [ ! -f vftool.bash ]; then
  echo 'vftool.bash must exist in the directory you are executing the script from'
  echo '(please fix this at least in new-foreman-clients.bash)'
  exit 1
fi

get_ipaddr() {
  sshhost=$1
  ipaddr=$(grep "$sshhost.example.com" /etc/hosts | perl -p -i -e 's/^(\S+)\s+.*$/$1/')
  if [ "x$ipaddr" = "x" ]; then
    fatal "Failed find ipaddr for $sshhost.example.com in /etc/hosts"
  fi
  echo $ipaddr
}

## create the vm's
#echo "creating $NUMHOSTS vm's"
#SKIP_FOREMAN_CLIENT_REGISTRATION=true export SKIPSNAP=true \
#  $MCS_SCRIPTS_DIR/client-vms/new-foreman-clients.bash $NUMHOSTS

# derive variables
vmset="${VMSET_CHUNK}1"
controllerhost="${VMSET_CHUNK}1"
storagehosts=""
i=2
while [ $i -le $NUMHOSTS ]; do
  vm="$VMSET_CHUNK$i"
  vmset="$vmset $vm"
  storagehosts="$storagehosts= $vm"
  i=$[$i+1]
done
storagehosts=$(echo $storagehosts |perl -p -e 's/^ //')
export ALL_VMS=$vmset

##VMSET=$ALL_VMS vftool.bash wait_for_port 22
##SNAPNAME=$PRE_PACK_SNAPNAME vftool.bash reboot_snap_take $ALL_VMS
##VMSET=$ALL_VMS vftool.bash wait_for_port 22

# derive ip variables
ipcontrollerhost=$(get_ipaddr "$controllerhost")
ipstoragehosts=""
i=2
while [ $i -le $NUMHOSTS ]; do
  vm="$VMSET_CHUNK$i"
  theipaddr=$(get_ipaddr "$vm")
  ipstoragehosts="$ipstoragehosts,$theipaddr"
  i=$[$i+1]
done
ipstoragehosts=$(echo $ipstoragehosts |perl -p -e 's/^,//')

# create the packstack answer file
packansfile=/mnt/vm-share/tmp/packstack.ans.$$
cp $MCS_SCRIPTS_DIR/packstack/swift-small/packstack.ans.template $packansfile
perl -p -i -e "s/CONTROLLERHOST/$ipcontrollerhost/" $packansfile
perl -p -i -e "s/SWIFTSTORAGEHOSTS/$ipstoragehosts/" $packansfile

# prep $controllerhost, also where packstack runs from
##VMSET=$controllerhost vftool.bash run "yum -y install openstack-packstack python-netaddr"
# give it the ssh keys to the kingdom
sudo scp -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" \
  /root/.ssh/id_rsa /root/.ssh/id_rsa.pub  root@$controllerhost:/root/.ssh
VMSET=$controllerhost vftool.bash run "packstack --answer-file=$packansfile"
