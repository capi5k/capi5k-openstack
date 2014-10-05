class openstackg5k::utils::gems {
	package { 'rubygems': 
		ensure => installed,
	}

  	# Ruby gems we want installed
  	package { 'mixlib-cli':
    		provider => 'gem',
    		ensure => installed,
    		require => Package['rubygems']
  	}
	package { 'net-ssh-multi':
    		provider => 'gem',
    		ensure => installed,
    		require => Package['rubygems']
  	}

	package { 'net-scp':
    		provider => 'gem',
    		ensure => installed,
    		require => Package['rubygems']
  	}
}
