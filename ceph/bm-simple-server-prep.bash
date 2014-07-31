# Make sure the storage node host where we will execute
# simple-cluster.bash from has password-less ssh access to other
# nodes.  Since this bm host already has ssh keys configured that
# (assuming vftool was installed), we re-use those.
#
# To be run on bare-metal host.

nodename=c1a4
VMSET=c1a4 vftool.bash run "yum -y install rsync"
rsync -e ssh -a  /root/.ssh/id_rsa* root@$nodename:/root/.ssh
