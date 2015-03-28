#!/bin/bash

scriptdir=$(cd $(dirname "$0"); pwd) 

# e.g., how to set the ha params on an existing foreman install
# (to be run on the foreman node)

if $(rpm -q --queryformat "%{RPMTAG_VERSION}" foreman | grep -qP '^(2|1.[6789])') ; then

  /usr/share/openstack-foreman-installer/bin/quickstack_defaults.rb \
    -d $scriptdir/ha-quickstack.yaml.erb \
    -g $scriptdir/ha-hostgroups.yaml hostgroups -v
  /usr/share/openstack-foreman-installer/bin/quickstack_defaults.rb \
    -d $scriptdir/ha-quickstack.yaml.erb \
    -g $scriptdir/ha-hostgroups.yaml parameters -v

else

  echo 'SKIPPING running quickstack_defaults.rb due to old foreman'

fi
