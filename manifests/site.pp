node basenode {
}

node default {
}

node 'puppet' {
  class { 'puppetdb': }
  class { 'puppetdb::master::config': }
}
