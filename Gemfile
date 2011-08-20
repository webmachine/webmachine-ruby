source :rubygems

gemspec

gem 'bundler'

unless ENV['TRAVIS']
  gem 'guard-rspec'
  gem 'rb-fsevent'
  gem 'growl'
  gem 'growl_notify'
end

platforms :jruby do
  gem 'jruby-openssl'
end
