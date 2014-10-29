# The puppet module to set up a Nova local storage
class openstackg5k::profile::nova::storage {
  # we just bound /var/lib/instances to some directory in /tmp
  file { '/tmp/instances':
    ensure => directory,
    owner  => 'nova',
    group  => 'nova',
    # TODO be more restrictive ...
    mode   => 777 
  }

  mount { '/var/lib/nova/instances':
    ensure  => mounted,
    device  => '/tmp/instances',
    fstype  => 'none',
    options => 'rw,bind',
    require => File['/tmp/instances']
  }
}
