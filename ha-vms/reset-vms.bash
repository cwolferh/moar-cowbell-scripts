## assuming you have run setup-ha-vms.bash, this is the reset button.

# set these 4 variables
export INITIMAGE=rhel6rdo
foreman_node='s6fore1'
chunk='s6ha1'
snapname=ready_for_mysql2

export VMSET="${chunk}c1 ${chunk}c2 ${chunk}c3 ${chunk}nfs "

bash -x vftool.bash stop_guests

# we want the foreman node to be online before the clients are reverted
SNAPNAME=$snapname bash -x vftool.bash reboot_snap_revert $foreman_node
sleep 60
#
SNAPNAME=$snapname bash -x vftool.bash reboot_snap_revert $VMSET
