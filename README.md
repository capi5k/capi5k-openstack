capi5k-openstack
=================

### Summary

  * Overview
    * What kind of deployment is it ?
    * Prerequisites : see http://capi5k.github.io/capi5k/
  * Deploy
    * Check the deployment
  * Boot VMs
    * Using Nova
    * Using EC2
    * Using the web interface
  * Customize the deployment

## Overview

### What kind of deployment is it ?

* Base image : ubuntu1204
* Openstack Icehouse
* Legacy network configured to be high available (one nova-network / compute node)
* Nodes are put in a VLAN (global only, support for local routed VLAN in progress)

Boostrap with the following:

* One base image (can be adapted easily in the ```Capfile```)
```
nova image-list
+--------------------------------------+--------------+--------+--------+
| ID                                   | Name         | Status | Server |
+--------------------------------------+--------------+--------+--------+
| ec350d7b-e075-4725-baa0-42fc547a277b | ubuntu-13.10 | ACTIVE |        |
+--------------------------------------+--------------+--------+--------+
```
* One network used for the VMs IPs (automatically generated from the vlan network)
```
nova net-list
+--------------------------------------+----------+----------------+
| ID                                   | Label    | CIDR           |
+--------------------------------------+----------+----------------+
| 8462e71b-81ce-4d0f-8bfd-10f8bb73b29c | net-jdoe | 10.27.230.0/24 |
+--------------------------------------+----------+----------------+
```
* 2 specific users (see ```common.yml.erb```)
  * demo is in the demo tenant
  * test has admin permissions.

```
keystone user-list
+----------------------------------+------------+---------+---------------------------+
|                id                |    name    | enabled |           email           |
+----------------------------------+------------+---------+---------------------------+
| 59fc0746333b47eab928bc05dcc5b576 |    demo    |   True  |      demo@example.com     |
| ac5d82e9217c42e3af2e51466ecbf2c7 |    test    |   True  |      test@example.com     |
...
+----------------------------------+------------+---------+---------------------------+
```
* Some files generated on the controller

```
$ ls -l
total 242380
-rw-r--r-- 1 root root       441 Nov 17 17:02 admin.ec2 # user test EC2 credentials
-rw-r--r-- 1 root root       441 Nov 17 17:02 demo.ec2  # user demo EC2 credentials
-rw-r--r-- 1 root root       233 Nov 17 17:02 demorc    # user demo internal API exports
-rwx------ 1 root root       446 Nov 17 16:29 openrc    # user admin internal API exports
...
```

### Prerequisites : see http://capi5k.github.io/capi5k/

## Deploy

* ``` xpm install ```
* ``` bundle install ```

Submit / Deploy linux base image, bootstrap a puppet cluster on the nodes.
* ```cap automatic puppetcluster; cap puppetcluster``` (yes, twice puppetcluster ... see below)

Note : for deployment at scale, one can use ```cap puppetcluster:passenger``` in addition to provide
passenger support to the puppet master.

Deploy openstack.
*  ```cap openstack```

Run some initializations
*  ```cap openstack:boostrap```


## check the deployment

* ```cap describe```

```
+----------------------------------------------------------------------+
|puppet_master                 parapluie-31-kavlan-16.rennes.grid5000.fr|
+----------------------------------------------------------------------+
|puppet_clients                parapluie-8-kavlan-16.rennes.grid5000.fr|
|                              parapluie-32-kavlan-16.rennes.grid5000.fr|
|                              parapluie-35-kavlan-16.rennes.grid5000.fr|
|                              parapluie-38-kavlan-16.rennes.grid5000.fr|
+----------------------------------------------------------------------+
|controller                    parapluie-32-kavlan-16.rennes.grid5000.fr|
+----------------------------------------------------------------------+
|storage                       parapluie-32-kavlan-16.rennes.grid5000.fr|
+----------------------------------------------------------------------+
|openstack                     parapluie-8-kavlan-16.rennes.grid5000.fr|
|                              parapluie-32-kavlan-16.rennes.grid5000.fr|
|                              parapluie-35-kavlan-16.rennes.grid5000.fr|
|                              parapluie-38-kavlan-16.rennes.grid5000.fr|
+----------------------------------------------------------------------+
|compute                       parapluie-8-kavlan-16.rennes.grid5000.fr|
|                              parapluie-38-kavlan-16.rennes.grid5000.fr|
+----------------------------------------------------------------------+
|frontend                      rennes                                  |
+----------------------------------------------------------------------+
```
* ssh to controller as root
* (controller) ```source openrc```
* (controller) ```nova-manage service list | sort```

```bash
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

## Boot VMs

### Using nova

```
# use demo user
(controller) source demorc
(controller) nova boot --flavor 3 --security_groups vm_jdoe_sec_group --image ubuntu-image --nic net-id=a665bfd4-53da-41a8-9bd6-bab03c09b890 --key_name jdoe_key  ubuntu-vm
```

Note : Get the list of nets / images  ...
```
nova net-list
nova image-list
nova secgroup-list
nova keypair-list
````


### Using the EC2 interface


```
# check access/secret key
(controller) cat demo.ec2
(controller) EC2_ACCESS_KEY=224de6d07e5342dea886f64384e8d27e EC2_SECRET_KEY=8d70469c8fba4b7194d1f0276d33b813 EC2_URL=http://10.27.204.144:8773/services/Cloud euca-run-instances -n 1 -g vm_jdoe_sec_group -k jdoe_key -t m1.medium ubuntu-13.10
```

### Using the web Gui

```
(laptop) ssh -NL 8000:parapluie-32-kavlan-16.rennes.grid5000.fr:80 access.grid5000.fr
```
And then visit ```http://127.0.0.1:8000/horizon```

## Customize the deployment

 * You'll find some tuning possibilities in templates/common.yml.erb
 The hiera store is generated using this file.

 * Some classes are overriden to fit into G5K  (see openstackg5k module)
