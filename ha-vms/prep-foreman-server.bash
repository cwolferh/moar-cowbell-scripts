# Intended to be run on the foreman server.
#
# ***Before*** running foreman_server.sh:
#   copy $ASTAPOR to standard installer location
#   copy puppet-pacemaker puppet modules to standard installer location
#   set default test passwords instead of the default long random hex keys
#
# I prefer to do it this way rather than running foreman_server.sh
# straight from ASTAPOR.  bin/foreman-params.json gets rewritten in
# place.  So, if your ASTAPOR is a git checkout, now you've got
# updates.  And you've got the wrong values for say 'foreman_server'
# if you try running it on a different foreman server.  But worse,
# you've added chaos to the system if you rerun the installer (unless
# you git revert) on the fresh system.
#

ASTAPOR=${ASTAPOR:=/mnt/vm-share/astapor}
PUPPET_PACEMAKER=${PUPPET_PACEMAKER:=/mnt/vm-share/puppet-pacemaker}

if [ -d /etc/puppet/environments/production/modules ]; then
  echo 'WARNING: /etc/puppet/environments/production/modules ALREADY EXISTS.'
  echo 'THIS MAY NOT BE A PRE-foreman_server.sh-RUN SERVER'
  echo 'CONTINUING ANYWAY'
fi

mv /usr/share/openstack-foreman-installer /usr/share/openstack-foreman-installer-RPM-ORIG

cp -ra $ASTAPOR /usr/share/openstack-foreman-installer
find /usr/share/openstack-foreman-installer -name '.git' | xargs rm -rf

# easy default passwords please
perl -p -i -e "s/SecureRandom\.hex/'weakpw'/g" \
  /usr/share/openstack-foreman-installer/bin/seeds.rb

# The Things They Carried
# (I could be talking about puppet-pacemaker, or I could be talking
#  about a great novel, highly recommended)
#
mkdir -p /usr/share/packstack/modules
rm -rf  /usr/share/packstack/modules/pacemaker
cp -r $PUPPET_PACEMAKER /usr/share/packstack/modules/pacemaker
find /usr/share/packstack/modules/pacemaker -name '.git' | xargs rm -rf
# below worked *before* pacemaker was added to packstack-modules-puppet
#mkdir -p /etc/puppet/environments/production/modules
#rm -rf  /etc/puppet/environments/production/modules/pacemaker
#cp -r $PUPPET_PACEMAKER /etc/puppet/environments/production/modules/pacemaker
#find /etc/puppet/environments/production/modules/pacemaker -name '.git' | xargs rm -rf
