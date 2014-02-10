# assumption: foreman node and vftool already installed

export INITIMAGE=${INITIMAGE:=rhel65swift}
export INSTALLURL=${INSTALLURL:='http://yourrhel6mirror.com/somepath/os/x86_64'}
REG_SCRIPT=${REG_SCRIPT:='/path/to/your/yum-or-rhn-setup-script'}
FOREMAN_NODE=${FOREMAN_NODE:=s14fore1}
VMSET_CHUNK=sw1a
NUM_CLIS=3
ASTAPOR=https://github.com/redhat-openstack/astapor
BRANCH=master

source /mnt/vm-share/vftool/vftool.bash

kick_first_swift_vm(){

[[ -z $INSTALLURL ]] && fatal "INSTALLURL Is not defined"

domname=$initimage
image=$poolpath/$domname.qcow2
test -f $image && fatal "image $image already exists"
sudo /usr/bin/qemu-img create -f qcow2 -o preallocation=metadata $image 12G

cat >/tmp/$domname.ks <<EOD
%packages
@base
@core
nfs-utils
emacs-nox
emacs-common
screen
nc
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
part /boot --fstype ext4 --size=400
part swap --size=100
part /swift --fstype ext4 --size 2200
part pv.01 --size=8000
volgroup lv_admin --pesize=32768 pv.01
logvol / --fstype ext4 --name=lv_root --vgname=lv_admin --size=7000 --grow
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
    --disk $image,format=qcow2 \
    --ram 7000 \
    --vcpus 3 \
    --cpu host \
    --hvm \
    --os-variant rhel6 \
    --vnc

echo "view the install (if you want) with:"
echo "   virt-viewer --connect qemu+ssh://root@`hostname`/system $domname"
}

kick_first_swift_vm

sleep 60
echo 'waiting for kick_first_swift_vm to complete'
check='$(virsh domstate '$INITIMAGE' | grep -q "shut off")'
while ! eval $check; do
  sleep 10
  echo .
done

# install the foreman client vm's
INITIMAGE=$INITIMAGE           \
FOREMAN_NODE=$FOREMAN_NODE \
UNATTENDED=true            \
REG_SCRIPT=$REG_SCRIPT \
FOREMAN_CLIENT_SCRIPT=/mnt/vm-share/${FOREMAN_NODE}_client.sh \
SKIPSNAP=true              \
VMSET_CHUNK=$VMSET_CHUNK   \
bash -x /mnt/vm-share/mcs/client-vms/new-foreman-clients.bash $NUM_CLIS

vftool.bash configure_nic ${VMSET_CHUNK}1 static eth5 192.168.203.2 255.255.255.0
vftool.bash configure_nic ${VMSET_CHUNK}2 static eth5 192.168.203.3 255.255.255.0
vftool.bash configure_nic ${VMSET_CHUNK}3 static eth5 192.168.203.4 255.255.255.0
