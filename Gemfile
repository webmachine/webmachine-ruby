require 'rbconfig'

source :rubygems

gemspec

gem 'bundler'

group :webservers do
  gem 'mongrel',  '~> 1.2.beta', :platform => [:mri, :rbx]
  gem 'reel',     '>= 0.1.0', :platform => [:ruby_19, :jruby]
  gem 'hatetepe', '~> 0.5'
end

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
