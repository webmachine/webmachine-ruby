require 'rbconfig'

source :rubygems

gemspec

gem 'bundler'

unless ENV['TRAVIS']
  gem 'guard-rspec'

  platform :mri do
    gem 'redcarpet'

    case RbConfig::CONFIG['host_os']
    when /darwin/
      gem 'rb-fsevent'
      gem 'growl_notify'
    when /linux/
      gem 'rb-inotify'
      gem 'libnotify'
    end
  end
end

platforms :jruby do
  gem 'jruby-openssl'
end
