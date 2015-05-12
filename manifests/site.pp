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

}

node 'gitlab' {
  class { 'gitlab':
    gitlab_branch        => '7.10.4',
    external_urla        => 'http://gitlab.chriscowley.me.uk',
    gitlab_download_link => 'https://packages.gitlab.com/gitlab/gitlab-ce/packages/el/7/gitlab-ce-7.10.4~omnibus-1.x86_64.rpm'
  }
}
