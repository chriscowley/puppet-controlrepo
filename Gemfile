source "http://rubygems.org"
gem "rake", '11.2.2'
gem 'hiera', '3.2.0'
group :test do
  gem "beaker", '2.44.0'
  gem "beaker-rspec", '5.4.0'
  gem "puppet-lint", '1.1.0'
  gem "puppet", ENV['PUPPET_VERSION'] || '~> 4.4.2'
  gem "rspec-puppet", :git => 'https://github.com/rodjek/rspec-puppet.git'
  gem "puppet-syntax", '2.1.0'
  gem "puppetlabs_spec_helper", '1.1.1'
  gem "metadata-json-lint", '0.0.11'
  gem "r10k", '2.3.0'
  gem "hiera-eyaml", '2.1.0'
end

group :development do
  gem "travis"
  gem "travis-lint"
  gem "beaker", '2.44.0'
  gem "beaker-rspec",  '5.4.0'
  gem "vagrant-wrapper"
  gem "puppet-blacksmith"
  gem "guard-rake"
  gem "pry"
  gem "yard"
end
