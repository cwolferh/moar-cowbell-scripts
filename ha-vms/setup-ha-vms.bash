# set these 5 variables
export INITIMAGE=${INITIMAGE:=rhel6rdo}
FOREMAN_NODE=${FOREMAN_NODE:=s14fore1}
VMSET_CHUNK=${VMSET_CHUNK:=s14ha1}
# nic for the 192.168.200.0 network that mysql lives on
hanic=eth2
# This client script must exist before running current file
# for now, cp it from /tmp to your chosen location/name, will
# automate more in future
FOREMAN_CLIENT_SCRIPT=${FOREMAN_CLIENT_SCRIPT:=/mnt/vm-share/rdo/${FOREMAN_NODE}_foreman_client.sh}

# 3 VM's in a mysql HA-cluster.  one VM houses nfs shared-storage.
export VMSET="${VMSET_CHUNK}c1 ${chunk}c2 ${chunk}c3 ${chunk}nfs"

bash -x vftool.bash create_images
bash -x vftool.bash prep_images
bash -x vftool.bash start_guests
bash -x vftool.bash populate_etc_hosts
bash -x vftool.bash populate_default_dns

echo 'press a key when the network is back up'
read


# populating dns restarts the network, so need to restart the foreman server
bash -x vftool.bash destroy_if_running $FOREMAN_NODE
sudo virsh start $FOREMAN_NODE

echo 'press a key to continue when the foreman web UI is up'
read

for domname in $VMSET; do
  ## XXXXXXXXXXXXXXX enter ther name of your client script below
  sudo ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" \
  $domname "bash ${FOREMAN_CLIENT_SCRIPT}"
done

# install augeas on nfs server (its not subscribed to foreman and
# didn't run the client script that normally installs augeas
sudo ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" ${VMSET_CHUNK}nfs "yum -y install augeas" 

mkdir /mnt/vm-share/tmp
for i in 1 2 3 4; do
  DOMNAME=${VMSET_CHUNK}c$i
  IPADDR=192.168.200.1$i
  if [ "$DOMNAME" = "${VMSET_CHUNK}c4" ]; then
     DOMNAME=${VMSET_CHUNK}nfs
     IPADDR=192.168.200.200
  fi
    
  cat > /mnt/vm-share/tmp/$DOMNAME-ifconfig.bash <<EOCAT

augtool <<EOA
set /files/etc/sysconfig/network-scripts/ifcfg-$hanic/BOOTPROTO none
set /files/etc/sysconfig/network-scripts/ifcfg-$hanic/IPADDR    $IPADDR
set /files/etc/sysconfig/network-scripts/ifcfg-$hanic/NETMASK   255.255.255.0
set /files/etc/sysconfig/network-scripts/ifcfg-$hanic/NM_CONTROLLED no
set /files/etc/sysconfig/network-scripts/ifcfg-$hanic/ONBOOT    yes
save
EOA

ifup eth2
EOCAT
done

for i in 1 2 3 4; do
  DOMNAME=${VMSET_CHUNK}c$i
  IPADDR=192.168.200.1$i
  if [ "$DOMNAME" = "${VMSET_CHUNK}c4" ]; then
     DOMNAME=${VMSET_CHUNK}nfs
  fi
  
  sudo ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" $DOMNAME "bash -x /mnt/vm-share/tmp/$DOMNAME-ifconfig.bash"
done

# disable nfs v4 so that mounted /var/lib/mysql works
sudo ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" ${VMSET_CHUNK}nfs "sed -i 's/#RPCNFSDARGS=\"-N 4\"/RPCNFSDARGS=\"-N 4\"/' /etc/sysconfig/nfs"
# install the nfs rpm so we get the mysql system (/etc/passwd) user
sudo ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" ${VMSET_CHUNK}nfs "yum -y install mysql" 
# create nfs mount point on the nfs server.  ready to be mounted!
sudo ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" ${VMSET_CHUNK}nfs "mkdir -p /mnt/mysql; chmod ugo+rwx /mnt/mysql; echo '/mnt/mysql 192.168.200.0/16(rw,sync,no_root_squash)' >> /etc/exports; /sbin/service nfs restart; /sbin/chkconfig nfs on" 

SNAPNAME=new_foreman_cli bash -x vftool.bash reboot_snap_take $VMSET $FOREMAN_NODE
