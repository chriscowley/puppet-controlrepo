node default {
  hiera_include('classes')
  #  basepackages = {
  #   'wget', 'vim',
  #}
  collectd::plugin::write_graphite::carbon { $::fqdn:
    graphitehost    => 'stats.chriscowley.lan',
    graphiteport    => '2003',
    protocol        => 'tcp',
    graphiteprefix  => 'servers.',
    logsenderrors   => true,
    storerates      => true,
    alwaysappendds  => false,
    escapecharacter => '_',
  }
  class {'etchosts::client': }
    case $::osfamily {
    'RedHat': {
      class {'epel': }
    }
     default: {
    }
  }
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
    'metrics': {
      apache::vhost { 'graphite.chriscowley.lan':
        port                                => '80',
        docroot                           => '/opt/graphite/webapp',
        wsgi_application_group          => '%{GLOBAL}',
        wsgi_daemon_process           => 'graphite',
        wsgi_daemon_process_options => {
          processes               => '5',
          threads                 => '5',
          display-name            => '%{GROUP}',
          inactivity-timeout      =>  '120',
        },
        wsgi_import_script           => '/opt/graphite/conf/graphite.wsgi',
        wsgi_import_script_options => {
          process-group          => 'graphite',
          application-group      =>  '%{GLOBAL}'
        },
        wsgi_process_group    => 'graphite',
        wsgi_script_aliases => {
          '/'             =>  '/opt/graphite/conf/graphite.wsgi'
        },
        headers => [
          'set Access-Control-Allow-Origin "*"',
          'set Access-Control-Allow-Methods "GET, OPTIONS, POST"',
          'set Access-Control-Allow-Headers "origin, authorization, accept"',
        ],
      }
    }
    'web-frontend': {
      class {'apache':}
    }
    'puppet': {
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
      class { 'puppetboard::apache::vhost':
        vhost_name => 'puppetboard.chriscowley.lan',
        port       => '80',
      }
    }
    'monitor': {
    }
    'ci': {
      package { 'git':
        ensure => 'latest',
      }
#      class { 'diamond':
#        graphite_host => 'stats.chriscowley.lan',
#      }
      user { 'jenkins':
        ensure => 'present'
      }
      single_user_rvm::install { 'jenkins':
        home => '/var/lib/jenkins/',
      }
      single_user_rvm::install_ruby { 'ruby-2.1.3':
        user => 'jenkins',
        home => '/var/lib/jenkins/',
      }
      jenkins::plugin { 'rebuild': }
      jenkins::plugin { 'git-client': }
      jenkins::plugin { 'scm-api': }
      jenkins::plugin { 'token-macro': }
      jenkins::plugin { 'parameterized-trigger': }
      jenkins::plugin { 'git': }
      jenkins::plugin { 'gitlab-plugin': }
      jenkins::plugin { 'ruby-runtime': }
      jenkins::plugin { 'rvm': }
      jenkins::plugin { 'shiningpanda': }
      jenkins::plugin { 'publish-over-ssh': }

      file { '/var/lib/jenkins/.virtualenvs':
        ensure  => directory,
        owner   => 'jenkins',
        group   => 'jenkins',
        require => User['jenkins'],
      }
      python::virtualenv {'/var/lib/jenkins/jobs/justanotherlinuxblog/':
        ensure     => present,
        venv_dir   => '/var/lib/jenkins/.virtualenvs/pelcan',
        systempkgs => false,
        distribute => false,
        owner      => 'jenkins',
        group      => 'jenkins',
        cwd        => '/var/lib/jenkins/jobs/justanotherlinuxblog/',
      }
    }
    'package': {
      class {'::mongodb::server': }
    }
  }
}

node 'puppet' {
  class { 'puppetdb':   }
  class { 'puppetdb::master::config':
    puppet_service_name => 'puppetserver',
  }
#  class { 'puppetboard':
#    manage_git        => latest,
#    manage_virtualenv => latest,
#  }
#  class { 'apache': }
#  class { 'apache::mod::wsgi':
#    wsgi_socket_prefix => '/var/run/wsgi',
#
#  }
#  # Access Puppetboard from example.com/puppetboard
#  class { 'puppetboard::apache::vhost':
#    vhost_name => 'puppetboard.chriscowley.lan',
#    port       => '80',
#  }
}

node 'gitlab' {
  class {'etchosts::client': }
}
    
#node 'dns1' {
  #class { 'etchosts': }
  ##class { 'dnsmasq': }
  #Class['etchosts'] ~> Class['dnsmasq']
  #}
