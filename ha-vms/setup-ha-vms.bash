# creates 4 vms, 3 for the ha mysql cluster, one nfs shared storage

# set these variables
export INITIMAGE=${INITIMAGE:=rhel6rdo}
FOREMAN_NODE=${FOREMAN_NODE:=s14fore1}
VM_PREFIX=${VM_PREFIX:=s14ha2}
CLUSUBNET=${CLUSUBNET:=192.168.203}
# nic for the CLUSUBNET network that mysql lives on
HANIC=${HANIC:=eth3}
MCS_SCRIPTS_DIR=${MCS_SCRIPTS_DIR:=/mnt/vm-share/mcs}
UNATTENDED=${UNATTENDED:=false}

## TODO -- use ../foreman/new-foreman-clients.bash for basic setup

# you may want to hold off on foreman_client.sh registration for later
# (especially if you are going to be in the habit of reverting
#  foreman to a pre-foreman_server.sh state as part of testing),
# in which case set this to true
SKIP_FOREMAN_CLIENT_REGISTRATION=${SKIP_FOREMAN_CLIENT_REGISTRATION:=false}

SNAPNAME=${SNAPNAME:=new_foreman_cli}

# if false, wait for user input to continue after key steps.
UNATTENDED=${UNATTENDED:=false}

# if you want to run a script that registers and configures your rhel
# repos, this is the place to reference that script.  otherwise, leave
# blank.
SCRIPT_HOOK_REGISTRATION=${SCRIPT_HOOK_REGISTRATION:=''}

# 3 VM's in a mysql HA-cluster.  one VM houses nfs shared-storage.
export VMSET="${VM_PREFIX}c1 ${VM_PREFIX}c2 ${VM_PREFIX}c3 ${VM_PREFIX}nfs"
HASET="${VM_PREFIX}c1 ${VM_PREFIX}c2 ${VM_PREFIX}c3"
NFSSET="${VM_PREFIX}nfs"

if ! which vftool.bash; then
  echo 'vftool.bash must be in your PATH'
  exit 1
fi

#VMSET_CHUNK='' \
#SKIP_FOREMAN_CLIENT_REGISTRATION=$SKIP_FOREMAN_CLIENT_REGISTRATION \
#SCRIPT_HOOK_REGISTRATION=$SCRIPT_HOOK_REGISTRATION \
#UNATTENDED=$UNATTENDED \
#SKIPSNAP=false \
#SNAPNAME=pre_ha_config \
#bash -x $MCS_SCRIPTS_DIR/client-vms/new-foreman-clients.bash
#
#vftool.bash wait_for_port 22

echo "VMs created!  Now, installing HA-specific rpm's"

# install packages we'll need on the HA nodes
# (puppet/foreman_client.sh would do this for us later, but we can
# save time by having the packages pre-installed in our snap)
#
# Need upstream repo for pacemaker
#sudo mkdir -p /mnt/vm-share/tmp; sudo chmod ogo+rwx /mnt/vm-share/tmp;
#cat >/mnt/vm-share/tmp/clusterlabs.repo <<EOF
#[clusterlabs]
#baseurl=http://clusterlabs.org/64z.repo
#enabled=1
#gpgcheck=0
#priority=1
#EOF

for domname in $HASET; do
  #ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" \
  #  root@$domname "yum-config-manager --enable rhel-ha-for-rhel-6-server-rpms"
  # set clusterlabs repo
  #ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" \
  #  root@$domname "cp /mnt/vm-share/tmp/clusterlabs.repo /etc/yum.repos.d/clusterlabs.repo"
  ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" \
    root@$domname "yum -y install mysql-server MySQL-python ccs pcs cman"
  ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" \
    root@$domname "yum -y install puppet augeas"
done

# install augeas on nfs server (its not subscribed to foreman and
# didn't run the client script that normally installs augeas...
ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" \
 root@${VM_PREFIX}nfs "yum -y install augeas mysql"

SNAPNAME=more_ha_rpms vftool.bash reboot_snap_take
vftool.bash wait_for_port 22

echo "RPM's installed.  Now, beginning networiking HA / NFS config"

# TODO script augeas-is-installed check (pause script if not)

mkdir -p /mnt/vm-share/tmp
for i in 1 2 3 4; do
  DOMNAME=${VM_PREFIX}c$i
  IPADDR=$CLUSUBNET.1$i
  if [ "$DOMNAME" = "${VM_PREFIX}c4" ]; then
     DOMNAME=${VM_PREFIX}nfs
     IPADDR=$CLUSUBNET.200
  fi

  cat > /mnt/vm-share/tmp/$DOMNAME-ifconfig.bash <<EOCAT

augtool <<EOA
set /files/etc/sysconfig/network-scripts/ifcfg-$HANIC/BOOTPROTO none
set /files/etc/sysconfig/network-scripts/ifcfg-$HANIC/IPADDR    $IPADDR
set /files/etc/sysconfig/network-scripts/ifcfg-$HANIC/NETMASK   255.255.255.0
set /files/etc/sysconfig/network-scripts/ifcfg-$HANIC/NM_CONTROLLED no
set /files/etc/sysconfig/network-scripts/ifcfg-$HANIC/ONBOOT    yes
save
EOA

ifup $HANIC
EOCAT

done

for i in 1 2 3 4; do
  DOMNAME=${VM_PREFIX}c$i
  IPADDR=$CLUSUBNET.1$i
  if [ "$DOMNAME" = "${VM_PREFIX}c4" ]; then
     DOMNAME=${VM_PREFIX}nfs
  fi

  sudo ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" $DOMNAME "bash -x /mnt/vm-share/tmp/$DOMNAME-ifconfig.bash"
done

# disable nfs v4 so that mounted /var/lib/mysql works
sudo ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" ${VM_PREFIX}nfs "sed -i 's/#RPCNFSDARGS=\"-N 4\"/RPCNFSDARGS=\"-N 4\"/' /etc/sysconfig/nfs"
# install the mysql rpm so we get the mysql system (/etc/passwd) user
sudo ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" ${VM_PREFIX}nfs "yum -y install mysql"
# create nfs mount point on the nfs server.  ready to be mounted!
echo sudo ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" ${VM_PREFIX}nfs "mkdir -p /mnt/mysql; chmod ugo+rwx /mnt/mysql; echo '/mnt/mysql $CLUSUBNET.0/16(rw,sync,no_root_squash)' >> /etc/exports; /sbin/service nfs restart; /sbin/chkconfig nfs on"

sudo ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" ${VM_PREFIX}nfs "mkdir -p /mnt/mysql; chmod ugo+rwx /mnt/mysql; echo '/mnt/mysql $CLUSUBNET.0/16(rw,sync,no_root_squash)' >> /etc/exports; /sbin/service nfs restart; /sbin/chkconfig nfs on"

if [ "$SKIP_FOREMAN_CLIENT_REGISTRATION" = "false" ]; then
  SNAPNAME=$SNAPNAME bash -x vftool.bash reboot_snap_take $VMSET $FOREMAN_NODE
else 
  SNAPNAME=$SNAPNAME bash -x vftool.bash reboot_snap_take $VMSET
fi