node basenode {
}

node default {
}

node 'puppet' {
  class { 'puppetdb':
    $puppet_service_name = 'puppetserver',
  }
  class { 'puppetdb::master::config': }
}
