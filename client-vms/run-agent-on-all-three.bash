export VMSET=${VMSET:="c1a1 c1a2 c1a3"}
export SLEEP=${SLEEP:=0}
thedir=/mnt/vm-share/logs/`date +%s`
mkdir -p $thedir
lastvm=$(echo $VMSET | perl -p -e 's/^.*\s+(\S+)$/$1/')

cat >/mnt/vm-share/puppet-with-timestamp.sh <<EOF
puppet agent -tvd --trace --color=false 2>&1 | awk -v hostname=\$(hostname -s) '{print hostname" " strftime("%H:%M:%S") " " \$0}'

EOF


for vm in $VMSET; do
 cmd="bash /mnt/vm-share/puppet-with-timestamp.sh | tee $thedir/$vm-puppet-out.txt"
 VMSET=$vm vftool.bash run $cmd &
 test "$vm" == "$lastvm" || sleep $SLEEP
done

rm -f /mnt/vm-share/logs/latest
ln -s $thedir /mnt/vm-share/logs/latest
