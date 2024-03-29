﻿require_relative 'lib/webmachine/version'

Gem::Specification.new do |gem|
  gem.name = 'webmachine'
  gem.version = Webmachine::VERSION
  gem.summary = %(webmachine is a toolkit for building HTTP applications,)
  gem.description = <<-DESC.gsub(/\s+/, ' ')
    webmachine is a toolkit for building HTTP applications in a declarative fashion, that avoids
    the confusion of going through a CGI-style interface like Rack. It is strongly influenced
    by the original Erlang project of the same name and shares its opinionated nature about HTTP.
  DESC
  gem.homepage = 'https://github.com/webmachine/webmachine-ruby'
  gem.authors = ['Sean Cribbs']
  gem.email = ['sean@basho.com']
  gem.license = 'Apache-2.0'

  gem.metadata['allowed_push_host'] = 'https://rubygems.org'
  gem.metadata['bug_tracker_uri'] = "#{gem.homepage}/issues"
  gem.metadata['changelog_uri'] = "#{gem.homepage}/blob/HEAD/CHANGELOG.md"
  gem.metadata['documentation_uri'] = "https://www.rubydoc.info/gems/webmachine/#{gem.version}"
  gem.metadata['homepage_uri'] = gem.homepage
  gem.metadata['source_code_uri'] = gem.homepage
  gem.metadata['wiki_uri'] = "#{gem.homepage}/wiki"

  gem.required_ruby_version = '>= 2.6.0'

  gem.add_runtime_dependency('as-notifications', ['>= 1.0.2', '< 2.0'])
  gem.add_runtime_dependency('base64')
  gem.add_runtime_dependency('i18n', ['>= 0.4.0'])
  gem.add_runtime_dependency('multi_json')

  ignores = File.read('.gitignore').split(/\r?\n/).reject { |f| f =~ /^(#.+|\s*)$/ }.map { |f| Dir[f] }.flatten
  gem.files = (Dir['**/*', '.gitignore'] - ignores).reject do |f|
    !File.file?(f) || f.start_with?(*%w[. Gemfile RELEASING Rakefile doc/ memory_test pkg/ spec/ vendor/ webmachine.gemspec])
  end
end
