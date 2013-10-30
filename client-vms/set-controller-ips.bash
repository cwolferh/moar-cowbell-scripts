export MCS_SCRIPTS_DIR=${MCS_SCRIPTS_DIR:=/mnt/vm-share/mcs}

ssh root@$1 "bash $MCS_SCRIPTS_DIR/run-on-vm/static-controller-ips.bash"
