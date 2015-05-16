node basenode {
}

node default {
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
    wsgi_socket_prefix => "/var/run/wsgi",

  }
  # Access Puppetboard from example.com/puppetboard
  class { 'puppetboard::apache::vhost': 
    vhost_name => 'puppetboard.chriscowley.lan',
    port       => '80',
  }
  class {'golang':
    base_dir => '/usr/local/go',
    version  => 'go1.4.1',
    goroot    =>  "$GOPATH/bin:/usr/local/go/bin:$PATH",
    workdir   => '/usr/local/',
  }
}

node 'gitlab' {
}
