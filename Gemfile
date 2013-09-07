require 'rbconfig'

source 'https://rubygems.org'

gemspec

gem 'bundler'

group :webservers do
  gem 'mongrel',  '~> 1.2.beta', :platform => [:mri, :rbx]

  if RUBY_VERSION >= '1.9'
    gem 'reel', '~> 0.3.0', :platform => [:ruby_19, :ruby_20, :jruby]
  end

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
  platform :mri_19, :mri_20 do
    gem 'redcarpet'
  end
end

platforms :jruby do
  gem 'jruby-openssl'
end
