require 'rbconfig'

source :rubygems

gemspec

gem 'bundler'
gem 'bluecloth'
gem 'yard'

unless ENV['TRAVIS']
  gem 'guard-rspec'

  case RbConfig::CONFIG['host_os']
  when /darwin/
    gem 'rb-fsevent'
    gem 'growl_notify'
  when /linux/
    gem 'rb-inotify'
    gem 'libnotify'
  end
end

platforms :jruby do
  gem 'jruby-openssl'
end
