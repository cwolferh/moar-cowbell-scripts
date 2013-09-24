# set these 4 variables
export INITIMAGE=rhel6rdo
foreman_node='s6fore1'
chunk='s6ha1'
# nic for the 192.168.200.0 network that mysql lives on
hanic=eth2

# 3 VM's in a mysql HA-cluster.  one VM houses nfs shared-storage.
export VMSET="${chunk}c1 ${chunk}c2 ${chunk}c3 ${chunk}nfs"

bash -x vftool.bash create_images
bash -x vftool.bash prep_images
bash -x vftool.bash start_guests
bash -x vftool.bash populate_etc_hosts
bash -x vftool.bash populate_default_dns

echo 'press a key when the network is back up'
read


# populating dns restarts the network, so need to restart the foreman server
sudo virsh destroy $foreman_node
sudo virsh start $foreman_node

echo 'press a key to continue when the foreman web UI is up'
read

for domname in $VMSET; do
  ## XXXXXXXXXXXXXXX enter ther name of your client script below
  sudo ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" $domname 'bash /mnt/vm-share/rdo/s6fore1_foreman_client.sh'
done

# create nfs mount point on the nfs server.  ready to be mounted!
sudo ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" ${chunk}nfs "mkdir -p /mnt/mysql; chmod ugo+rwx /mnt/mysql; echo '/mnt/mysql 192.168.200.0/16(rw,sync,no_root_squash)' >> /etc/exports; /sbin/service nfs restart; /sbin/chkconfig nfs on" 
# install augeas on nfs server (its not subscribed to foreman and
# didn't run the client script that normally installs augeas
sudo ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" ${chunk}nfs "yum -y install augeas" 

mkdir /mnt/vm-share/tmp
for i in 1 2 3 4; do
  DOMNAME=${chunk}c$i
  IPADDR=192.168.200.1$i
  if [ "$DOMNAME" = "${chunk}c4" ]; then
     DOMNAME=${chunk}nfs
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
  DOMNAME=${chunk}c$i
  IPADDR=192.168.200.1$i
  if [ "$DOMNAME" = "${chunk}c4" ]; then
     DOMNAME=${chunk}nfs
  fi
  
  sudo ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" $DOMNAME "bash -x /mnt/vm-share/tmp/$DOMNAME-ifconfig.bash"
done

SNAPNAME=new_foreman_cli bash -x vftool.bash reboot_snap_take $VMSET $foreman_node
