# The profile to set up the Nova controller (several services)
class openstackg5k::profile::nova::api {
  openstack::resources::controller { 'nova': }
  openstack::resources::database { 'nova': }
  openstack::resources::firewall { 'Nova API': port => '8774', }
  openstack::resources::firewall { 'Nova Metadata': port => '8775', }
  openstack::resources::firewall { 'Nova EC2': port => '8773', }
  openstack::resources::firewall { 'Nova S3': port => '3333', }
  openstack::resources::firewall { 'Nova novnc': port => '6080', }

  class { '::nova::keystone::auth':
    password         => hiera('openstack::nova::password'),
    public_address   => hiera('openstack::controller::address::api'),
    admin_address    => hiera('openstack::controller::address::management'),
    internal_address => hiera('openstack::controller::address::management'),
    region           => hiera('openstack::region'),
    cinder           => true,
  }

  nova_config { 
	'DEFAULT/network_api_class': value => 'nova.network.api.API';
	'DEFAULT/security_group_api': value => 'nova';
  }
  include ::openstackg5k::common::nova
}
