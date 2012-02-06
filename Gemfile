require 'rbconfig'

source :rubygems

gemspec

gem 'bundler'

group :guard do
  gem 'guard-rspec'
  case RbConfig::CONFIG['host_os']
  when /darwin/
    gem 'rb-fsevent'
    # gem 'growl_notify'
    gem 'growl'
  when /linux/
    gem 'rb-inotify'
    gem 'libnotify'
  end
end

group :docs do
  platform :mri do
    gem 'redcarpet'
  end
end

platforms :jruby do
  gem 'jruby-openssl'
end
