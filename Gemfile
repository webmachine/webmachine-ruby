require 'rbconfig'

source :rubygems

gemspec

gem 'bundler'

unless ENV['TRAVIS']
  gem 'guard-rspec'

  if RbConfig::CONFIG['host_os'] =~ /darwin/
    gem 'rb-fsevent'
    gem 'growl'
    gem 'growl_notify'
  end
end

platforms :jruby do
  gem 'jruby-openssl'
end
