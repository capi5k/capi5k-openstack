node 'puppet' {
  include ::ntp
}

node 'paradent-14-kavlan-4.rennes.grid5000.fr' {
	include ::openstackg5k::role::controller
}

node 'paradent-11-kavlan-4.rennes.grid5000.fr','paradent-12-kavlan-4.rennes.grid5000.fr','paradent-10-kavlan-4.rennes.grid5000.fr','paradent-13-kavlan-4.rennes.grid5000.fr' {
  include ::openstackg5k::role::compute
}
