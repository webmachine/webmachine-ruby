$:.push File.expand_path("../lib", __FILE__)
require 'webmachine/version'

Gem::Specification.new do |gem|
  gem.name = "webmachine"
  gem.version = Webmachine::VERSION
  gem.summary = %Q{webmachine is a toolkit for building HTTP applications,}
  gem.description = <<-DESC.gsub(/\s+/, ' ')
    webmachine is a toolkit for building HTTP applications in a declarative fashion, that avoids
    the confusion of going through a CGI-style interface like Rack. It is strongly influenced
    by the original Erlang project of the same name and shares its opinionated nature about HTTP.
  DESC
  gem.homepage = "http://github.com/seancribbs/webmachine-ruby"
  gem.authors = ["Sean Cribbs"]
  gem.email = ["sean@basho.com"]
  gem.license = "Apache 2.0"

  gem.add_runtime_dependency(%q<i18n>, [">= 0.4.0"])
  gem.add_runtime_dependency(%q<multi_json>)
  gem.add_runtime_dependency(%q<as-notifications>, ["~> 1.0"])

  ignores = File.read(".gitignore").split(/\r?\n/).reject{ |f| f =~ /^(#.+|\s*)$/ }.map {|f| Dir[f] }.flatten
  gem.files = (Dir['**/*','.gitignore'] - ignores).reject {|f| !File.file?(f) }
  gem.test_files = (Dir['spec/**/*','features/**/*','.gitignore'] - ignores).reject {|f| !File.file?(f) }
end
