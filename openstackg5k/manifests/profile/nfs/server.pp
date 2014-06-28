#The nfs module to set up the server node.
class openstackg5k::profile::nfs::server {
        $network_addr = hiera('openstack::network::api')
        package {'nfs-kernel-server':
                ensure => installed,
        }


        file {'/etc/exports':
                ensure => file,
                require => Package['nfs-kernel-server'],
				content => "/var/lib/nova/instances     $network_addr(rw,fsid=0,insecure,no_subtree_check,sync,no_root_squash)",
        }

        file {'/var/lib/nova/instances':
                ensure => directory,
                mode => 'o+xw',
        }
        service {'nfs-kernel-server':
                name => 'nfs-kernel-server',
                ensure => running,
                enable => true,
                subscribe => File['/etc/exports'],
        }
        exec {'/etc/init.d/idmapd restart':
                subscribe => File['/etc/exports'],
        }


}

