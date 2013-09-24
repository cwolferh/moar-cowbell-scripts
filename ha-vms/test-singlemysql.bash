bash -x /mnt/pub/rdo/ha/reset-vms.bash
rm /mnt/vm-share/modules/singlemysql/*/*~
scp -r /mnt/vm-share/modules/singlemysql root@s6fore1:/etc/puppet/environments/production/modules/