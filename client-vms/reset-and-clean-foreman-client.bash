#!/bin/bash

# Sample usage:
#   REVERT_CLIS=true VMSET="c1a2 c1a3" FOREMAN_NODE=fore1a SNAPNAME=pre_foreman_cli FOREMAN_CLIENT_SCRIPT=/mnt/vm-share/fore1a_client.sh ./reset-and-clean-foreman-client.bash
#
# Note that the hosts are disassociated from their hostgroups.

# assumes CLI_NODE at SNAPNAME is pre-foreman registration
export VMSET=${VMSET:="c1a1 c1a2 c1a3"}
REVERT_CLIS=${REVERT_CLIS:=false}
SNAPNAME=${SNAPNAME:=pre_foreman_cli}

FOREMAN_NODE=${FOREMAN_NODE:=fore1a}

FOREMAN_CLIENT_SCRIPT=${FOREMAN_CLIENT_SCRIPT:=/mnt/vm-share/rdo/foreman_client_${FOREMAN_NODE}.sh}
MCS_SCRIPTS_DIR=${MCS_SCRIPTS_DIR:=/mnt/vm-share/mcs}

which vftool.bash || exit 1

VMSET=$FOREMAN_NODE vftool.bash run "$MCS_SCRIPTS_DIR/foreman/api/hosts.rb clear_hostgroup $VMSET"

if [ "$REVERT_CLIS" = "true" ]; then
  SNAPNAME=$SNAPNAME vftool.bash reboot_snap_revert $VMSET
fi
vftool.bash wait_for_port 22
vftool.bash run "killall puppet; rm -rf /var/lib/puppet/ssl;"

for vm in $VMSET; do
  # call clean twice
  VMSET=$FOREMAN_NODE vftool.bash run "puppet cert clean ${vm}.example.com; puppet cert clean ${vm}.example.com"
done

#VMSET=$FOREMAN_NODE vftool.bash run "/etc/init.d/httpd restart"
#VMSET=$FOREMAN_NODE vftool.bash wait_for_port 443

vftool.bash run "killall puppet; rm -rf /var/lib/puppet/ssl; bash -x $FOREMAN_CLIENT_SCRIPT"

