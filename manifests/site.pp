node cm.novalocal {
  class { 'puppet':
    runmode => 'service',
    server  => true,
    server_java_opts => '-Xms512m -Xmx512m',
    puppetmaster => 'cm.novalocal',
    server_version => 'latest',
  }
  class { 'puppetdb':}
  class { 'puppetdb::master::config': }
  class { 'hiera':
    hierarchy => [
      'nodes/%{clientcert}',
      'roles/%{role}',
      '%{environment}/%{calling_class}',
      '%{environment}',
      'common',
    ],
    datadir => '/etc/puppetlabs/code/hieradata',
    eyaml => true,
    create_keys => false,
    keysdir     => '/etc/puppetlabs/secure/keys'
  }
  class { 'r10k':
    remote => 'https://gogs.chriscowley.me.uk/chriscowley/puppet.git',
    provider => 'puppet_gem',
  }
}
