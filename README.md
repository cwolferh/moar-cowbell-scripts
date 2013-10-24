## Scripts to build up and configure Foreman/RDO/OpenStack VM's

Relies on vftool.bash from https://github.com/cwolferh/vms-and-foreman

The more stable scripts are:

### Install Foreman

https://github.com/cwolferh/moar-cowbell-scripts/blob/master/foreman/install-foreman.bash
(see comments at top of script)

### Setup 3 VM's as a HA-mysql cluster, another as an NFS server
and optionally subscribe them to your foreman node.

https://github.com/cwolferh/moar-cowbell-scripts/blob/master/ha-vms/setup-ha-vms.bash
(see comments at top of script)

### Revert Foreman, 3 cluster nodes and the NFS node, re-configure.

https://github.com/cwolferh/moar-cowbell-scripts/blob/master/ha-vms/test-hamysql-full-foreman-revert.bash

The point of this script is to re-test a foreman install and client
registration without rebuilding VM's from scratch.  $FOREMAN_SNAPNAME
is a snap of the foreman server that has the relevant rpm's installed
but has not yet had foreman_server.sh run on it.  $SNAPNAME for the 3
clustered hosts likewise have not yet had foreman_client.sh run.  And
the nfs node at $SNAPNAME has a clean /mnt/mysql directory.

Most of the action takes place on the foreman node, where we
optionally point to a different foreman installer source location (aka
Astapor) and run foreman_server.sh.
