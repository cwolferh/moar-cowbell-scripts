#!/bin/bash

# e.g., how to set the ha params on an existing foreman install
# (to be run on the foreman node)

if $(rpm -q --queryformat "%{RPMTAG_VERSION}" foreman | grep -qP '^(2|1.[6789])') ; then

  /usr/share/openstack-foreman-installer/bin/quickstack_defaults.rb \
    -d /mnt/vm-share/mcs/foreman/config/ha-quickstack.yaml.erb \
    -g /mnt/vm-share/mcs/foreman/config/ha-hostroups.yaml parameters -v

else

  echo 'SKIPPING running quickstack_defaults.rb due to old foreman'

fi
