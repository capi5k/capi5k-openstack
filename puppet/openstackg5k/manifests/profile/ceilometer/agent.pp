class openstackg5k::profile::ceilometer::agent {
  class { '::openstackg5k::common::ceilometer': } ->
  class { '::ceilometer::agent::compute': }
}
