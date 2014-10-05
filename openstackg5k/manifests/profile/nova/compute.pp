# The puppet module to set up a Nova Compute node
class openstackg5k::profile::nova::compute {
  $management_network = hiera('openstack::network::management')
  $management_address = ip_for_network($management_network)

  class { 'openstackg5k::common::nova':
    is_compute => true,
  }

	#for migration:
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
  
}
