capi5k-openstack
=================

* ``` xpm install ```
* ``` bundle install ```
* ```cap automatic ; cap puppetcluster; cap puppetcluster; cap openstack; cap openstack:run_agents:network```
* ```cap openstack:bootstrap``` (generate keypair/net/sec-group)


## check the deployment

* cap describe
* ssh to controller as root
* (controller) source openrc
* (controller) nova-manage service list | sort

```
/python2.7/dist-packages/nova/servicegroup/drivers/db.py:71
Binary           Host                                 Zone             Status     State Updated_At
nova-cert        parapluie-32-kavlan-16.rennes.grid5000.fr internal         enabled    :-)   2014-10-07 14:49:18
nova-cert        parapluie-38-kavlan-16.rennes.grid5000.fr internal         enabled    XXX   None
nova-compute     parapluie-38-kavlan-16.rennes.grid5000.fr nova             enabled    :-)   2014-10-07 14:49:17
nova-compute     parapluie-8-kavlan-16.rennes.grid5000.fr nova             enabled    :-)   2014-10-07 14:49:24
nova-conductor   parapluie-32-kavlan-16.rennes.grid5000.fr internal         enabled    :-)   2014-10-07 14:49:24
nova-consoleauth parapluie-32-kavlan-16.rennes.grid5000.fr internal         enabled    :-)   2014-10-07 14:49:19
nova-network     parapluie-38-kavlan-16.rennes.grid5000.fr internal         enabled    :-)   2014-10-07 14:49:25
nova-network     parapluie-8-kavlan-16.rennes.grid5000.fr internal         enabled    :-)   2014-10-07 14:49:23
nova-scheduler   parapluie-32-kavlan-16.rennes.grid5000.fr internal         enabled    :-)   2014-10-07 14:49:24
```
