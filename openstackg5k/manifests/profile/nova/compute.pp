# The puppet module to set up a Nova Compute node
class openstackg5k::profile::nova::compute {
  $management_network = hiera('openstack::network::management')
  $management_address = ip_for_network($management_network)

  class { 'openstackg5k::common::nova':
    is_compute => true,
  }

  class { '::nova::compute::libvirt':
    libvirt_type     => hiera('openstack::nova::libvirt_type'),
    vncserver_listen => '0.0.0.0',
  }

  file { '/etc/libvirt/qemu.conf':
    ensure => present,
    source => 'puppet:///modules/openstack/qemu.conf',
    mode   => '0644',
    notify => Service['libvirt'],
  }

  Package['libvirt'] -> File['/etc/libvirt/qemu.conf']
  
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

  if $::osfamily == 'Debian' {

  	package { 'nova-network':
		ensure => installed,
	  }

  	package { 'nova-api-metadata':
		ensure => installed,
	  }
	

	service { 'nova-network':
        name => 'nova-network',
        ensure => running,
        enable => true,
        subscribe => File['/etc/nova/nova.conf'],
      }

    service { 'nova-api-metadata':
        name => 'nova-api-metadata',
        ensure => running,
        enable => true,
        subscribe => File['/etc/nova/nova.conf'],
		
      }

	}
}
