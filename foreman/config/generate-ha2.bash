# This copies an ha config and updates:
#  *static IP's with 192.168.200.1X0 addrs
#  *vip's to unique IP's
#  *hostnames to d1a_
#  *Openstack pacemaker name

# DOES NOT change hostgroup name, right now
# intended to be used on separate foreman server

SRC_DIR=${SRC_DIR:=/vs/mcs/foreman/config/ha}
DEST_DIR=${DEST_DIR:=/vs/mcs/foreman/config/ha2}

if [ -d $DEST_DIR ]; then
  echo $DEST_DIR already exists.  remove it and try again.
  exit 1
fi

cp -ra $SRC_DIR $DEST_DIR

perl -p -i -e 's/c1a/d1a/g' $DEST_DIR/ha-quickstack.yaml.erb
perl -p -i -e 's/osp6/osp7/g' $DEST_DIR/ha-quickstack.yaml.erb
perl -p -i -e 's/eth2/eth5/g' $DEST_DIR/ha-quickstack.yaml.erb
perl -p -i -e 's/openstackHA/SecondOpenstackHA/g' $DEST_DIR/ha-quickstack.yaml.erb
perl -p -i -e 's/192.168.200.10\b/192.168.111.110/g' $DEST_DIR/ha-quickstack.yaml.erb
perl -p -i -e 's/192.168.200.20\b/192.168.111.120/g' $DEST_DIR/ha-quickstack.yaml.erb
perl -p -i -e 's/192.168.200.30\b/192.168.111.130/g' $DEST_DIR/ha-quickstack.yaml.erb
perl -p -i -e 's/192.168.200.0\b/192.168.111.0/g' $DEST_DIR/ha-quickstack.yaml.erb
perl -p -i -e 's/192.168.201.13\b/192.168.201.14/g' $DEST_DIR/ha-quickstack.yaml.erb
perl -p -i -e 's/192.168.201.88\b/192.168.201.98/g' $DEST_DIR/ha-quickstack.yaml.erb
perl -p -i -e 's/192.168.201.87\b/192.168.201.97/g' $DEST_DIR/ha-quickstack.yaml.erb
perl -p -i -e 's/192.168.201.86\b/192.168.201.96/g' $DEST_DIR/ha-quickstack.yaml.erb
perl -p -i -e 's/192.168.201.85\b/192.168.201.95/g' $DEST_DIR/ha-quickstack.yaml.erb
perl -p -i -e 's/192.168.201.84\b/192.168.201.94/g' $DEST_DIR/ha-quickstack.yaml.erb
perl -p -i -e 's/192.168.201.83\b/192.168.201.93/g' $DEST_DIR/ha-quickstack.yaml.erb
perl -p -i -e 's/192.168.201.7\b/192.168.201.8/g' $DEST_DIR/ha-quickstack.yaml.erb
perl -p -i -e 's/192.168.201.25\b/192.168.201.28/g' $DEST_DIR/ha-quickstack.yaml.erb
perl -p -i -e 's/192.168.201.24\b/192.168.201.27/g' $DEST_DIR/ha-quickstack.yaml.erb
perl -p -i -e 's/192.168.201.23\b/192.168.201.26/g' $DEST_DIR/ha-quickstack.yaml.erb
perl -p -i -e 's/192.168.201.115\b/192.168.201.116/g' $DEST_DIR/ha-quickstack.yaml.erb
perl -p -i -e 's/192.168.201.125\b/192.168.201.128/g' $DEST_DIR/ha-quickstack.yaml.erb
perl -p -i -e 's/192.168.201.124\b/192.168.201.127/g' $DEST_DIR/ha-quickstack.yaml.erb
perl -p -i -e 's/192.168.201.114\b/192.168.201.112/g' $DEST_DIR/ha-quickstack.yaml.erb
perl -p -i -e 's/192.168.201.113\b/192.168.201.111/g' $DEST_DIR/ha-quickstack.yaml.erb
perl -p -i -e 's/192.168.201.95\b/192.168.201.93/g' $DEST_DIR/ha-quickstack.yaml.erb
perl -p -i -e 's/192.168.201.94\b/192.168.201.92/g' $DEST_DIR/ha-quickstack.yaml.erb
perl -p -i -e 's/192.168.7.100\b/192.168.7.200/g' $DEST_DIR/ha-quickstack.yaml.erb
perl -p -i -e 's/192.168.201.35\b/192.168.201.38/g' $DEST_DIR/ha-quickstack.yaml.erb
perl -p -i -e 's/192.168.201.34\b/192.168.201.37/g' $DEST_DIR/ha-quickstack.yaml.erb
perl -p -i -e 's/192.168.201.33\b/192.168.201.36/g' $DEST_DIR/ha-quickstack.yaml.erb
perl -p -i -e 's/192.168.201.53\b/192.168.201.54/g' $DEST_DIR/ha-quickstack.yaml.erb
perl -p -i -e 's/192.168.201.105\b/192.168.201.108/g' $DEST_DIR/ha-quickstack.yaml.erb
perl -p -i -e 's/192.168.201.104\b/192.168.201.107/g' $DEST_DIR/ha-quickstack.yaml.erb
perl -p -i -e 's/192.168.201.103\b/192.168.201.106/g' $DEST_DIR/ha-quickstack.yaml.erb
perl -p -i -e 's/192.168.201.56\b/192.168.201.57/g' $DEST_DIR/ha-quickstack.yaml.erb
perl -p -i -e 's/192.168.201.65\b/192.168.201.68/g' $DEST_DIR/ha-quickstack.yaml.erb
perl -p -i -e 's/192.168.201.64\b/192.168.201.67/g' $DEST_DIR/ha-quickstack.yaml.erb
perl -p -i -e 's/192.168.201.63\b/192.168.201.66/g' $DEST_DIR/ha-quickstack.yaml.erb
perl -p -i -e 's/192.168.201.73\b/192.168.201.74/g' $DEST_DIR/ha-quickstack.yaml.erb
perl -p -i -e 's/192.168.111.55\b/192.168.111.65/g' $DEST_DIR/ha-quickstack.yaml.erb
