require 'rbconfig'
source 'https://rubygems.org'
gemspec

group :development do
  gem "yard"
  gem "rake"
end

group :test do
  gem "rspec", '~> 3.0.0'
  gem "rspec-its"
  gem "rack"
  gem "rack-test"
end

group :webservers do
  gem 'reel', '~> 0.5.0'
  gem 'http', '~> 0.6.0'
  gem 'httpkit', :platform => [:mri, :rbx]
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
