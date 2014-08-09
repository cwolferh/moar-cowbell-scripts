export VMSET=${VMSET:="c1a1 c1a2 c1a3"}
export SLEEP=${SLEEP:=0}
thedir=/mnt/vm-share/logs/`date +%s`
mkdir -p $thedir
lastvm=$(echo $VMSET | perl -p -e 's/^.*\s+(\S+)$/$1/')

for vm in $VMSET; do
 cmd="puppet agent -tvd --trace --color=false 2>&1 | tee $thedir/$vm-puppet-out.txt"
 VMSET=$vm vftool.bash run $cmd &
 test "$vm" == "$lastvm" || sleep $SLEEP
done

rm -f /mnt/vm-share/logs/latest
ln -s $thedir /mnt/vm-share/logs/latest
