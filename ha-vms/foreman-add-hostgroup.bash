yum -y install ruby193-rubygem-minitest

# Get your puppet classes under /etc/puppet/environments/production/modules
# For example:
git clone https://github.com/cwolferh/puppet-hamysql.git /etc/puppet/environments/production/modules/hamysql

sudo -u foreman scl enable ruby193 "cd $FOREMAN_DIR; RAILS_ENV=production rake puppet:import:puppet_classes[batch]"

if [ "x$FOREMAN_DIR" = "x" ]; then
  FOREMAN_DIR=/usr/share/foreman
fi
cd $FOREMAN_DIR
cat <<EOF | sudo -u foreman scl enable ruby193 "RAILS_ENV=production rails console"
hostgroups = [
    {:name=>"HA Mysql Node",    
     :class=>"hamysql::node"},
]
hostgroups.each do |hg|
  h=Hostgroup.find_or_create_by_name hg[:name]
  h.environment = Environment.find_by_name('production')
  h.puppetclasses = [ Puppetclass.find_by_name(hg[:class])]
end

EOF
