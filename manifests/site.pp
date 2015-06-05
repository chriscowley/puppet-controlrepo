node default {
  class {'epel': }
  if ${::role} == 'sensu' {
  }
}
#node 'sensu' {
#  class { '::rabbitmq':
#  }
#}

node 'puppet' {
  class { 'puppetdb':   }
  class { 'puppetdb::master::config':
    puppet_service_name => 'puppetserver',
  }
  class { 'puppetboard':
    manage_git        => latest,
    manage_virtualenv => latest,
  }
  class { 'apache': }
  class { 'apache::mod::wsgi':
    wsgi_socket_prefix => '/var/run/wsgi',

  }
  # Access Puppetboard from example.com/puppetboard
  class { 'puppetboard::apache::vhost':
    vhost_name => 'puppetboard.chriscowley.lan',
    port       => '80',
  }
  class {'::ntp':
    servers => [
      '0.centos.pool.ntp.org',
      '1.centos.pool.ntp.org',
      '2.centos.pool.ntp.org',
      '3.centos.pool.ntp.org',
    ]
  }
}

node 'gitlab' {
  class {'etchosts::client': }
}
    
node 'dns1' {
  class { 'etchosts': }
  class { 'dnsmasq': }
  Class['etchosts'] ~> Class['dnsmasq']
}

node 'logger' {
  class {'etchosts::client': }
  class { 'logstash':
    java_install => true,
    manage_repo  => true,
  }
}
