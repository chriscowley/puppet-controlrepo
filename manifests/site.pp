node 'basenode' {
}

node 'default' {
}

node 'puppet' {
  class { 'puppetdb':   }
  class { 'puppetdb::master::config':
    puppet_service_name => 'puppetserver',
  }
  class { 'puppetboard':
    manage_git        => true,
    manage_virtualenv => true,
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
  class { 'etchosts': } ~>
  class { 'dnsmasq': }
}

node 'logger' {
  class { 'logstash':
    java_install => true,
    manage_repo  => true,
  }
}
