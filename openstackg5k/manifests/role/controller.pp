class openstackg5k::role::controller inherits ::openstack::role {
  class { '::openstack::profile::firewall': }
  class { '::openstack::profile::rabbitmq': } ->
  class { '::openstack::profile::memcache': } ->
  class { '::openstack::profile::mysql': } ->
  class { '::openstack::profile::mongodb': } ->
  class { '::openstack::profile::keystone': } ->
  class { '::openstack::profile::ceilometer::api': } ->
  class { '::openstack::profile::glance::auth': } ->
  class { '::openstack::profile::glance::api': } ->
  class { '::openstack::profile::cinder::api': } ->
  class { '::openstackg5k::profile::nova::api': } ->
  class { '::openstack::profile::heat::api': } ->
  class { '::openstack::profile::horizon': } ->
  class { '::openstackg5k::profile::nfs::server': }
  class { '::openstack::profile::auth_file': }
}
