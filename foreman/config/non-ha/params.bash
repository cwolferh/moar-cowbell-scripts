#!/bin/bash

scriptdir=$(cd $(dirname "$0"); pwd) 

if $(rpm -q --queryformat "%{RPMTAG_VERSION}" foreman | grep -qP '^(2|1.[6789])') ; then

  /usr/share/openstack-foreman-installer/bin/quickstack_defaults.rb \
    -d $scriptdir/quickstack.yaml.erb \
    -g $scriptdir/hostgroups.yaml parameters -v

else
  echo 'SKIPPING running quickstack_defaults.rb due to old foreman'
fi
