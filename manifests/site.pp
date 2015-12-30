node default {
  hiera_include('classes')
  package { 'nagios-plugins-all':
    ensure => latest,
  }
  package {'wget':
    ensure => installed,
  }
  package { 'bind-utils':
    ensure => installed,
  }
  file { '/opt/sensu-plugins':
    ensure  => directory,
    require => Package['wget'],
  }
  staging::deploy { 'sensu-community-plugins.tar.gz':
    source  => 'https://github.com/sensu/sensu-community-plugins/archive/master.tar.gz',
    target  => '/opt/sensu-plugins',
    require => File['/opt/sensu-plugins'],
  }
  collectd::plugin::write_graphite::carbon { $::fqdn:
    graphitehost    => 'stats.chriscowley.lan',
    graphiteport    => '2003',
    protocol        => 'tcp',
    graphiteprefix  => 'servers.',
    logsenderrors   => true,
    storerates      => true,
    alwaysappendds  => true,
    escapecharacter => '_',
  }
  sensu::check { 'check_disk':
    command     => '/opt/sensu-plugins/sensu-community-plugins-master/plugins/processes/check-disk.rb',
    handlers    => 'default',
    subscribers => 'base',
    require     =>  Staging::Deploy['sensu-community-plugins.tar.gz'],
  }
  class {'etchosts::client': }
  case $::osfamily {
    'RedHat': {
      class {'epel': }
    }
    default: {
    }
  }
  class { 'selinux':
    mode => 'permissive',
    type => 'targeted',
  }
  selinux::boolean { 'collectd_tcp_network_connect': }
  case $::role {
    'dns': {
      class {'etchosts':}
      class { 'dnsmasq': }
      Class['etchosts'] ~> Class['dnsmasq']
      sysctl { 'net.ipv4.ip_forward': value =>  '1' }
      #      openvpn::server { 'home.chriscowley.me.uk':
      #  country      => 'FR',
      #  province     => 'Bretagne',
      #  city         => 'Rennes',
      #  organization => 'chriscowley.me.uk',
      #  email        => 'chris@chriscowley.me.uk',
      #  server       => '10.200.200.0 255.255.255.0',
      #  proto        => 'udp',
      #}
      #openvpn::client {'motog':
      #  server => 'home.chriscowley.me.uk'
      #}
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
        port                        => '80',
        docroot                     => '/opt/graphite/webapp',
        wsgi_application_group      => '%{GLOBAL}',
        wsgi_daemon_process         => 'graphite',
        wsgi_daemon_process_options => {
          processes          => '5',
          threads            => '5',
          display-name       => '%{GROUP}',
          inactivity-timeout =>  '120',
        },
        wsgi_import_script          => '/opt/graphite/conf/graphite.wsgi',
        wsgi_import_script_options  => {
          process-group     => 'graphite',
          application-group =>  '%{GLOBAL}'
        },
        wsgi_process_group          => 'graphite',
        wsgi_script_aliases         => {
          '/' =>  '/opt/graphite/conf/graphite.wsgi'
        },
        headers                     => [
          'set Access-Control-Allow-Origin "*"',
          'set Access-Control-Allow-Methods "GET, OPTIONS, POST"',
          'set Access-Control-Allow-Headers "origin, authorization, accept"',
        ],
      }
      class {'collectd::plugin::snmp':
        data  => {
          std_traffic => {
            'Type'     => 'if_octets',
            'Table'    => true,
            'Instance' => 'IF-MIB::ifDescr',
            'Values'   => 'IF-MIB::ifInOctets" "IF-MIB::ifOutOctets',
          }
        },
        hosts => {
          swlab01 => {
            'Address'   => 'swlab01.chriscowley.lan',
            'Version'   => 2,
            'Community' => 'public',
            'Collect'   => ['std_traffic'],
            'Interval'  => 10,
          }
        },
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
      rabbitmq_user  {'sensu':
        admin    => false,
        password => 'password',
      }
      rabbitmq_vhost { '/sensu':
        ensure => present,
      }
      sensu::check { 'check_cron':
        command     => '/opt/sensu-plugins/sensu-community-plugins-master/plugins/processes/check-procs.rb -p crond -C   1',
        handlers    => 'default',
        subscribers => 'base',
        require     =>  Staging::Deploy['sensu-community-plugins.tar.gz'],
      }
      sensu::check { 'check_puppet':
        command     => '/opt/sensu-plugins/sensu-community-plugins-master/plugins/processes/check-procs.rb -p puppet -C   1',
        handlers    => 'default',
        subscribers => 'base',
        require     =>  Staging::Deploy['sensu-community-plugins.tar.gz'],
      }
    }
    'gitlab': {

    }
    'ci': {
      package { 'git':
        ensure => 'latest',
      }
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
    'toolbox': {
      mysql::db {'gogs':
        user     => 'gogs',
        password => 'correcthorsebatterystaple',
        host     => '%',
        grant    => ['ALL'],
      }
    }
    default: {
    }
  }
}

#node 'dns1' {
  #class { 'etchosts': }
  ##class { 'dnsmasq': }
  #Class['etchosts'] ~> Class['dnsmasq']
  #}
