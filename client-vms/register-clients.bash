# register $VMSET hosts to $FOREMAN_SERVER using $FOREMAN_CLIENT_SCRIPT

if [ ! -f $FOREMAN_CLIENT_SCRIPT ]; then
  echo '$FOREMAN_CLIENT_SCRIPT' with value of "$FOREMAN_CLIENT_SCRIPT" does not exist
  exit 1
fi

VMSET="$VMSET $FOREMAN_NODE" vftool.bash wait_for_port 22
VMSET="$FOREMAN_NODE" vftool.bash wait_for_port 443

for domname in $VMSET; do
  ssh -o "UserKnownHostsFile /dev/null" -o "StrictHostKeyChecking no" \
      root@$domname "bash $FOREMAN_CLIENT_SCRIPT 2>&1 | tee -a /tmp/foreman_client_sh.out 2>&1"
done
