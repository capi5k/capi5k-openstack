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
