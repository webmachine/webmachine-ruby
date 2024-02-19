require 'rbconfig'
source 'https://rubygems.org'
gemspec

group :development do
  gem 'yard', '~> 0.9'
  gem 'rake', '~> 12.0'
end

group :test do
  gem 'rspec', '~> 3.0', '>= 3.6.0'
  gem 'rspec-its', '~> 1.2'
  gem 'rack', '~> 2.0'
  gem 'rack-test', '~> 0.7'
  gem 'websocket_parser', '~>1.0'
end

group :docs do
  platform :mri_19, :mri_20 do
    gem 'redcarpet', '~> 3.4'
  end
end

platforms :jruby do
  gem 'jruby-openssl'
end

if RUBY_VERSION >= '3.4'
  gem 'mutex_m' # TODO: remove this once as-notifications has such a dependency
end
