node default {
  #  basepackages = {
  #   'wget', 'vim',
  #}
  hiera_include('classes')
  class {'etchosts::client': }
  case $::osfamily {
    'RedHat': {
      class {'epel': }
    }
  }
  class { 'erlang': }
  case $::role {
    'dns': {
      class {'etchosts':}
      class { 'dnsmasq': }
      Class['etchosts'] ~> Class['dnsmasq']
    }
    'logger': {
      package { 'wget':
        ensure => latest,
      }
      class {'elasticsearch':
        #     manage_repo => true,
        #repo_version     => '1.5',
        package_url       => 'https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-1.6.0.noarch.rpm',
      }
      elasticsearch::instance { 'es-01': }
      class { 'logstash':
        java_install => true,
        manage_repo  => true,
      }
    }
    'mirror': {
      class {'::mongodb::server': }
      class { '::qpid::server':
        config_file => '/etc/qpid/qpidd.conf',
      }
    }
    'web-frontend': {
      class {'apache':}
    }
    'monitor': {
    }
    'ci': {
      user { 'jenkins':
        ensure => 'present'
      }
      single_user_rvm::install { 'jenkins':
        home => '/var/lib/jenkins/',
      }
      single_user_rvm::install_ruby { 'ruby-2.1.3':
        user => 'jenkins',
      }
      jenkins::plugin { 'rebuild': }
      jenkins::plugin { 'git-client': }
      jenkins::plugin { 'scm-api': }
      jenkins::plugin { 'token-macro': }
      jenkins::plugin { 'parameterized-trigger': }
      jenkins::plugin { 'git': }

      jenkins::plugin { 'ruby-runtime': }
      jenkins::plugin { 'rvm': }

      jenkins::plugin { 'shiningpanda': }
    }
  }
}

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
  #class {'::ntp':
    # servers => [
      #'0.centos.pool.ntp.org',
      #'1.centos.pool.ntp.org',
      #'2.centos.pool.ntp.org',
      #'3.centos.pool.ntp.org',
      #]
    #}
}

node 'gitlab' {
  class {'etchosts::client': }
}
    
#node 'dns1' {
  #class { 'etchosts': }
  ##class { 'dnsmasq': }
  #Class['etchosts'] ~> Class['dnsmasq']
  #}

