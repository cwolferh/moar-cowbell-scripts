# run on controller node:
# ceph auth get-key client.volumes >/mnt/vm-share/tmp/client.volumes.key

# the rest runs on compute node
echo "<secret ephemeral='no' private='no'>
      <uuid>77123ba2-ed14-4f28-a645-62699c647c53</uuid>
      <usage type='ceph'>
         <name>client.volumes secret</name>
      </usage>
   </secret>" >/mnt/vm-share/tmp/secret.xml

uuid=$(virsh secret-define --file /mnt/vm-share/tmp/secret.xml| perl -p -e 's/Secret (\S+) .*/$1/')

echo virsh secret-set-value --secret $uuid --base64 $(cat /mnt/vm-share/tmp/client.volumes.key)
virsh secret-set-value --secret $uuid --base64 $(cat /mnt/vm-share/tmp/client.volumes.key) # && rm /mnt/vm-share/tmp/client.volumes.key /mnt/vm-share/tmp/secret.xml
