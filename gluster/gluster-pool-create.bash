initimage=${INITIMAGE:=glusterzero}
export VMSET=${VMSET:="gluster1n1 gluster1n2"}
# you'll need a script that on vm-share that subscribes
# the host to rhs-2.0-for-rhel-6-server-rpms and
# rhel-scalefs-for-rhel-6-server-rpms
SCRIPT_HOOK_REGISTRATION=${SCRIPT_HOOK_REGISTRATION:=/mnt/vm-share/tmp/subscribe-gluster.sh}
gluvol=${GLUVOL:=spruce_one}

# our gluster vm's consist of two disks, so we do things a little
# differently from standard vftool.bash workflow

first_vm=$(echo $VMSET | perl -p -i -e 's/^(\S+)\s+?(.*)$/$1/')


if [ ! -e vftool.bash ]; then
  echo ye who enter here need vftool.bash
  exit 1
fi

source vftool.bash


kick_first_gluster_vm(){

[[ -z $INSTALLURL ]] && fatal "INSTALLURL Is not defined"

domname=$initimage
image=$poolpath/$domname.qcow2
disk2=$poolpath/${domname}disk2.qcow2
test -f $image && fatal "image $image already exists"
sudo /usr/bin/qemu-img create -f qcow2 -o preallocation=metadata $image 9G
sudo /usr/bin/qemu-img create -f qcow2 -o preallocation=metadata $disk2 5g
#
#read

cat >/tmp/$domname.ks <<EOD
%packages
@base
@core
nfs-utils
emacs-nox
emacs-common
screen
%end

reboot
firewall --disabled
install
url --url="$INSTALLURL"
rootpw --plaintext weakpw
auth  --useshadow  --passalgo=sha512
graphical
keyboard us
lang en_US
selinux --disabled
skipx
logging --level=info
timezone  America/Los_Angeles
bootloader --location=mbr --append="console=tty0 console=ttyS0,115200 rd_NO_PLYMOUTH"
clearpart --all
part /boot --fstype ext4 --size=200 --ondisk=/dev/vda
part swap --size=100 --ondisk=/dev/vda
part pv.01 --size=5000  --ondisk=/dev/vda
volgroup lv_admin --pesize=32768 pv.01
logvol / --fstype ext4 --name=lv_root --vgname=lv_admin --size=4000 --grow
zerombr
network --bootproto=dhcp --noipv6 --device=eth0

%post

mkdir -p /mnt/vm-share
mount $default_ip_prefix.1:/mnt/vm-share /mnt/vm-share
if [ ! -d /root/.ssh ]; then
  mkdir -p /root/.ssh
  chmod 700 /root/.ssh
fi
if [ -f /mnt/vm-share/authorized_keys ]; then
  cp /mnt/vm-share/authorized_keys /root/.ssh/authorized_keys
  chmod 0600 /root/.ssh/authorized_keys
fi
# TODO script register to RHN

%end

EOD

sudo virt-install --connect=qemu:///system \
    --network network:default \
    --network network:foreman1 \
    --network network:openstackvms1_1 \
    --network network:openstackvms1_2 \
    --network network:foreman2 \
    --network network:openstackvms2_1 \
    --network network:openstackvms2_2 \
    --initrd-inject=/tmp/$domname.ks \
    --extra-args="ks=file:/$domname.ks ksdevice=eth0 noipv6 ip=dhcp keymap=us lang=en_US" \
    --name=$domname \
    --location=$INSTALLURL \
    --disk path=$image,format=qcow2,bus=virtio \
    --disk path=$disk2,format=qcow2,bus=virtio \
    --ram 768 \
    --cpu=host \
    --vcpus=1 \
    --os-variant rhel6 \
    --vnc

echo "view the install (if you want) with:"
echo "   virt-viewer --connect qemu+ssh://root@`hostname`/system $domname"
}

create_images_twodisk() {
  ATTEMPTS=60
  FAILED=0
  while $(sudo virsh list | grep -q "$initimage") ; do
    FAILED=$(expr $FAILED + 1)
    echo "waiting for $initimage to stop. $FAILED"
    if [ $FAILED -ge $ATTEMPTS ]; then
      fatal "create_images() $initimage must not be stopped to continue.  perhaps it is not done being installed yet."
    fi
    sleep 10
  done

  for domname in $vmset; do
    sudo virt-clone -o $initimage -n $domname -f $poolpath/$domname.qcow2 -f $poolpath/${domname}disk2.qcow2 && \
    sudo virt-sysprep -a $poolpath/$domname.qcow2 -a $poolpath/${domname}disk2.qcow2
  done
}

maybe_register() {
  if [ "x$SCRIPT_HOOK_REGISTRATION" != "x" ]; then
    for domname in $VMSET; do
      echo "running SCRIPT_HOOK_REGISTRATION"
      sudo ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" \
        $domname "bash ${SCRIPT_HOOK_REGISTRATION}"
    done
  fi
}

install_glu_packages() {
  for domname in $VMSET; do
    sudo ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" \
      $domname "yum -y install glusterfs-server"
  done
}

format_and_setup_bricks() {
  for domname in $VMSET; do
    ssh root@$domname "parted -s /dev/vdb unit MB mkpart primary 0% 100%;
     mkfs.xfs -i size=512 /dev/vdb1;
     mkdir /mnt/brick1;
     mkdir chmod 1777 /mnt/brick1;
     mount -t xfs /dev/vdb1 /mnt/brick1;
     service glusterd start"
  done

  tail_vmset=$(echo $VMSET | perl -p -i -e 's/^\S+\s+(.*)$/$1/')
  for domname in $tail_vmset; do
    ssh root@$first_vm "gluster peer probe gluster1n2"
  done
}

setup_gluster_volume() {
  cmd="gluster volume create $gluvol transport tcp"
  for domname in $VMSET; do
    cmd="$cmd $domname:/mnt/brick1"
  done
  ssh root@$first_vm $cmd
  ssh root@$first_vm "gluster volume start $gluvol"
  #echo $cmd
}

# start with gluster-specific calls
#
kick_first_gluster_vm
create_images_twodisk

# vanilla vftool.bash calls
#
bash -x vftool.bash prep_images
bash -x vftool.bash first_snaps
bash -x vftool.bash start_guests
bash -x vftool.bash populate_etc_hosts
bash -x vftool.bash populate_default_dns

# register, get storage rpms
#
maybe_register
install_glu_packages

# setup bricks, gluster volume
#
format_and_setup_bricks
setup_gluster_volume
