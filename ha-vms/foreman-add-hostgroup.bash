## Intended be run on the foreman-server
## Pick up new quickstack modules and changes in seeds.rb

ASTAPOR=/mnt/vm-share/astapor

if [ "x$FOREMAN_DIR" = "x" ]; then
  FOREMAN_DIR=/usr/share/foreman
fi
if [ "x$FOREMAN_PROVISIONING" = "x" ]; then
  FOREMAN_PROVISIONING=false
fi

# Re-import quickstack puppet classes
rm -rf  /etc/puppet/environments/production/modules/quickstack
cp -r $ASTAPOR/puppet/modules/quickstack /etc/puppet/environments/production/modules/quickstack
find /etc/puppet/environments/production/modules/quickstack -name '.git' | xargs rm -rf

sudo -u foreman scl enable ruby193 "cd $FOREMAN_DIR; RAILS_ENV=production rake puppet:import:puppet_classes[batch]"

cp $ASTAPOR/bin/seeds.rb /var/lib/foreman/db/seeds.rb

# re-run seeds.rb to get added hostgroup and host->hostgroup associations
sudo -u foreman scl enable ruby193 "cd $FOREMAN_DIR; rake --trace db:seed RAILS_ENV=production FOREMAN_PROVISIONING=$FOREMAN_PROVISIONING"
