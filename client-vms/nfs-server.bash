export VMSET=${VMSET:=c1anfs}
export NFS_SUBNET=${NFS_SUBNET:=192.168.0.0}
export NFS_MASKBITS=${NFS_MASKBITS:=16}

vftool.bash run "sed -i 's/#RPCNFSDARGS=\"-N 4\"/RPCNFSDARGS=\"-N 4\"/' /etc/sysconfig/nfs
mkdir -p /mnt/glance; chmod ug+rwx /mnt/glance; chown 161.161 /mnt/glance; echo '/mnt/glance ${NFS_SUBNET}/${NFS_MASKBITS}(rw,sync,no_root_squash)' >> /etc/exports;
mkdir -p /mnt/cinder; chmod ug+rwx /mnt/cinder; chown 165.165  /mnt/cinder; echo '/mnt/cinder ${NFS_SUBNET}/${NFS_MASKBITS}(rw,sync,no_root_squash)' >> /etc/exports;
/sbin/service nfs restart; 
grep -q 'release 6' /etc/redhat-release &&/sbin/chkconfig nfs on"
