
#this class should be applied separately because it conflicts with nova-api package installation
class openstackg5k::profile::nova::nova-legacy-net-compute {
        package {'nova-api':
                ensure => absent,
        }

	 nova_config {
        'DEFAULT/network_api_class': value => 'nova.network.api.API';
        'DEFAULT/security_group_api': value => 'nova';
        'DEFAULT/firewall_driver': value => 'nova.virt.libvirt.firewall.IptablesFirewallDriver';
        'DEFAULT/network_manager': value => 'nova.network.manager.FlatDHCPManager';
        'DEFAULT/network_size': value => '254';
        'DEFAULT/allow_same_net_traffic': value => 'False';
        'DEFAULT/multi_host': value => 'True';
        'DEFAULT/send_arp_for_ha': value => 'True';
        'DEFAULT/share_dhcp_address': value => 'True';
        'DEFAULT/force_dhcp_release': value => 'True';
        'DEFAULT/flat_network_bridge': value => 'br100';
        'DEFAULT/flat_interface': value => 'eth0';
        'DEFAULT/public_interface': value => 'eth0';
  	}


        package { 'nova-network':
                ensure => installed,
                require => Service['nova-api-metadata'],
          }


        service { 'nova-api':
                ensure => stopped,
        }

        package { 'nova-api-metadata':
               ensure => installed,
         }

  	service { 'nova-network':
                name => 'nova-network',
                ensure => running,
                enable => true,
              	subscribe => File['/etc/nova/nova.conf'],
                require => Package['nova-network'],
        }

        file {'/etc/nova/nova.conf':
                ensure => present,
        }

        service { 'nova-api-metadata':
                name => 'nova-api-metadata',
                ensure => running,
                enable => true,
                subscribe => File['/etc/nova/nova.conf'],
                require => Package['nova-api-metadata'],
      	}
}

