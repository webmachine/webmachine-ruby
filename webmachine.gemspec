$:.push File.expand_path("../lib", __FILE__)
require 'webmachine/version'

Gem::Specification.new do |gem|
  gem.name = "webmachine"
  gem.version = Webmachine::VERSION
  gem.date = File.mtime("lib/webmachine/version.rb")
  gem.summary = %Q{webmachine is a toolkit for building HTTP applications,}
  gem.description = <<-DESC.gsub(/\s+/, ' ')
    webmachine is a toolkit for building HTTP applications in a declarative fashion, that avoids
    the confusion of going through a CGI-style interface like Rack. It is strongly influenced
    by the original Erlang project of the same name and shares its opinionated nature about HTTP.
  DESC
  gem.homepage = "http://github.com/seancribbs/webmachine-ruby"
  gem.authors = ["Sean Cribbs"]
  gem.email = ["sean@basho.com"]

  if gem.respond_to? :specification_version then
    gem.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      gem.add_runtime_dependency(%q<i18n>, [">= 0.4.0"])
      gem.add_development_dependency(%q<rspec>, ["~> 2.6.0"])
      gem.add_development_dependency(%q<yard>, ["~> 0.6.7"])
      gem.add_development_dependency(%q<rake>)
      gem.add_development_dependency(%q<mongrel>, ['~>1.2.beta'])
      gem.add_development_dependency(%q<rack>)
    else
      gem.add_dependency(%q<i18n>, [">= 0.4.0"])
      gem.add_dependency(%q<rspec>, ["~> 2.6.0"])
      gem.add_dependency(%q<yard>, ["~> 0.6.7"])
      gem.add_dependency(%q<rake>)
      gem.add_dependency(%q<mongrel>, ['~>1.2.beta'])
      gem.add_dependency(%q<rack>)
    end
  else
    gem.add_dependency(%q<i18n>, [">= 0.4.0"])
    gem.add_dependency(%q<rspec>, ["~> 2.6.0"])
    gem.add_dependency(%q<yard>, ["~> 0.6.7"])
    gem.add_dependency(%q<rake>)
    gem.add_dependency(%q<mongrel>, ['~>1.2.beta'])
    gem.add_dependency(%q<rack>)
  end

  ignores = File.read(".gitignore").split(/\r?\n/).reject{ |f| f =~ /^(#.+|\s*)$/ }.map {|f| Dir[f] }.flatten
  gem.files = (Dir['**/*','.gitignore'] - ignores).reject {|f| !File.file?(f) }
  gem.test_files = (Dir['spec/**/*','features/**/*','.gitignore'] - ignores).reject {|f| !File.file?(f) }
  gem.executables   = Dir['bin/*'].map { |f| File.basename(f) }
  gem.require_paths = ['lib']
end
