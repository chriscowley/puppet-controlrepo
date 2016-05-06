node default {
  hiera_include('classes')
  class { 'packagecloud': }
  packagecloud::repo { 'chriscowleyunix/monitoring':
    type =>  'rpm',
  }

  package { 'nagios-plugins-all':
    ensure  => latest,
    require => Class['epel'],
  }
  package { 'htop':
    ensure  => latest,
    require => Class['epel'],
  }
  package { ['wget', 'unzip']:
    ensure => installed,
  }
  package { 'bind-utils':
    ensure => installed,
  }
  #  file { '/opt/sensu-plugins':
  #  ensure  => directory,
  #  require => Package['wget'],
  #}
  #staging::deploy { 'sensu-community-plugins.tar.gz':
  #  source  => 'https://github.com/sensu/sensu-community-plugins/archive/master.tar.gz',
  #  target  => '/opt/sensu-plugins',
  #  require => File['/opt/sensu-plugins'],
  #}
  package { 'sensu-plugins-disk-checks':
    ensure   => '1.1.3',
    provider => sensu_gem,
  }
  package { 'sensu-plugins-process-checks':
    ensure   => 'installed',
    provider => sensu_gem,
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
      class { 'dnsmasq': }
      #      Class['etchosts'] ~> Class['dnsmasq']
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
      elasticsearch::instance { 'es-01': }
    }
    'data': {
      $mysqldbs = hiera('mysqldb', {})
      create_resources('mysql::db', $mysqldbs)
      $mysqlusers = hiera('mysqluser', {})
      create_resources('mysql::user', $mysqlusers)
      $mysqlgrants = hiera('mysqlgrant', {})
      create_resources('mysql::grant', $mysqlgrants)
      package { ['gcc', 'mariadb-devel', 'openssl-devel']:
        ensure => latest,
      } ->
      package { 'sensu-plugins-mysql':
        ensure   => 'installed',
        provider => sensu_gem,
      }

      file { '/etc/sensu/my.conf':
        ensure => present,
        owner  => 'sensu',
        group  => 'sensu',
        mode   => '0440',
      }
      ini_setting {'sensutestuser':
        ensure  => present,
        path    => '/etc/sensu/my.cnf',
        section => 'client',
        setting => 'user',
        value   => 'sensutest',
      }
      #      ini_setting {'sensutestpassword':
      #  ensure  => present,
      #  path    => '/etc/sensu/my.cnf',
      #  section => 'client',
      #  setting => 'password',
      #  value   => $::mysqldb::sensutest::password,
      #}
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
    'puppet': {
      packagecloud::repo { 'chriscowleyunix/tools':
        type =>  'rpm',
      }
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
    }
    'package': {
      # user { 'gemmirror':
      #  ensure => present,
      #}
      #class {'::mongodb::server': }
    }
    'toolbox': {
      sshkeys::create_ssh_key { 'root':
        ssh_keytype => 'rsa',
      }
      class { 'backup': }
      mysql::db {'gogs':
        user     => 'gogs',
        password => 'correcthorsebatterystaple',
        host     => '%',
        grant    => ['ALL'],
      }
      hiera_resources('toolbox-dbs')
      hiera_resources('docker-images')
    }
    'web': {
      $webvhosts = hiera('apache::vhosts', {})
      create_resources('apache::vhost', $webvhosts)
    }
    default: {
    }
  }
  Class['epel']->Class['collectd']
}
