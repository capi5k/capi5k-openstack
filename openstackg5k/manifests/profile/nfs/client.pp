#Openstackg5k NFS module for client nodes
class openstackg5k::profile::nfs::client {
        $server_ip = hiera('openstack::controller::address::api')

        package { 'nfs-common':
                ensure => installed,
        }

        file { '/var/lib/nova/instances':
                ensure => directory,
                mode => 'o+xw',
        }

        exec { 'mount_instances':
                command => "mount $server_ip:/var/lib/nova/instances /var/lib/nova/instances",
                require => Package['nfs-common'],
                path => '/bin/',
        }

        exec { 'libvirtd.conf':
                command => 'sed --in-place=.old1 "s/^#listen_tls = 0.*$/listen_tls = 0/"  /etc/libvirt/libvirtd.conf',
                require => Package['nfs-common'],
                path => '/bin/',
        }
        exec { 'libvirtd.conf2':
                command => 'sed --in-place=.old2 "s/^#listen_tcp = 1.*$/listen_tcp = 1\nauth_tcp = \"none\"\n/" /etc/libvirt/libvirtd.conf',
                require => Package['nfs-common'],
                path => '/bin/',
        }
        exec { 'libvirt-bin.conf':
                command => 'sed --in-place=.old "s/exec \/usr\/sbin\/libvirtd $libvirtd_opts/exec \/usr\/sbin\/libvirtd $libvirtd_opts -l/" /etc/init/libvirt-bin.conf',
                require => Package['nfs-common'],
                path => '/bin/',
		}
        exec { 'libvirt-bin':
                command => 'sed --in-place=.old "s/libvirtd_opts=\"-d\"/libvirtd_opts=\" -d -l\"/" /etc/default/libvirt-bin',
                require => Package['nfs-common'],
                path => '/bin/',
        }

        exec { 'restart_libvirt':
                command => 'stop libvirt-bin && start libvirt-bin',
                path => '/sbin/',
				require => [Exec['libvirt-bin'], Exec['libvirt-bin'],Exec['libvirtd.conf2'],Exec['libvirtd.conf'],Exec['libvirt-bin.conf']],
        }
	
}

