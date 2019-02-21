#!/usr/bin/env python3
#
# Test OpenStack components are working.

import os, sys

if not os.environ['OS_PASSWORD']:
    sys.exit("I don't see OS_PASSWORD envvar, exiting ...")

command = {
    'nova_compute': 'openstack server list',
    'neutron': 'openstack network list',
    'cinder': 'openstack volume list',
    'glance': 'openstack image list',
}

for component, cmd in command.items():
    print("--> Testing {}: {}".format(component, cmd))
    os.system(cmd)
