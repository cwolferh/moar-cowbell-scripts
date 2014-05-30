thedir=/mnt/vm-share/logs/`date +%s`
mkdir -p $thedir

for vm in c1a1 ; do
 cmd="puppet agent -tvd --trace --color=false 2>&1 | tee $thedir/$vm-puppet-out.txt"
 VMSET=$vm vftool.bash run $cmd &
 sleep 22.5
done

for vm in c1a2; do
 cmd="puppet agent -tvd --trace --color=false 2>&1 | tee $thedir/$vm-puppet-out.txt"
 VMSET=$vm vftool.bash run $cmd &
 sleep 22.5
done

for vm in c1a3; do
 cmd="puppet agent -tvd --trace --color=false 2>&1 | tee $thedir/$vm-puppet-out.txt"
 VMSET=$vm vftool.bash run $cmd
done

exit 0
sleep 60 

for vm in c1a1 c1a2 c1a3; do
 cmd="pcs status 2>&1 | tee $thedir/$vm-pcs-status.txt"
 VMSET=$vm vftool.bash run $cmd &
done



