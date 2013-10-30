augtool <<EOA
set /files/etc/sysconfig/network-scripts/ifcfg-eth1/BOOTPROTO none
set /files/etc/sysconfig/network-scripts/ifcfg-eth1/IPADDR    192.168.200.11
set /files/etc/sysconfig/network-scripts/ifcfg-eth1/NETMASK   255.255.255.0
set /files/etc/sysconfig/network-scripts/ifcfg-eth1/NM_CONTROLLED no
set /files/etc/sysconfig/network-scripts/ifcfg-eth1/ONBOOT    yes
save
set /files/etc/sysconfig/network-scripts/ifcfg-eth2/BOOTPROTO none
set /files/etc/sysconfig/network-scripts/ifcfg-eth2/IPADDR    192.168.201.11
set /files/etc/sysconfig/network-scripts/ifcfg-eth2/NETMASK   255.255.255.0
set /files/etc/sysconfig/network-scripts/ifcfg-eth2/NM_CONTROLLED no
set /files/etc/sysconfig/network-scripts/ifcfg-eth2/ONBOOT    yes
save
EOA

ifup eth1
ifup eth2
