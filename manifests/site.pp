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
    manage_git        => 'latest',
    manage_virtualenv => 'latest',
  }
}
