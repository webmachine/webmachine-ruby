require 'rubygems'
require 'rake/gempackagetask'

gemspec = Gem::Specification.new do |gem|
  gem.name = "webmachine"
  gem.summary = %Q{webmachine is a toolkit for building HTTP applications,}
  gem.description = <<-DESC.gsub(/\s+/, ' ')
    webmachine is a toolkit for building HTTP applications in a declarative fashion, that avoids
    the confusion of going through a CGI-style interface like Rack. It is strongly influenced
    by the original Erlang project of the same name and shares its opinionated nature about HTTP.
    It uses the mongrel2 server underneath, since all other Ruby webservers are tied to the broken 
    CGI/Rack model.
  DESC
  gem.version = "0.1.0"
  gem.email = "sean@basho.com"
  gem.homepage = "http://seancribbs.github.com/webmachine-rb"
  gem.authors = ["Sean Cribbs"]
  # Just copying the mongrel2 adapter bits from this gem for now. We
  # need to extend things anyway.
  # gem.add_dependency "rack-mongrel2", "~> 0.2.3"
  gem.add_dependency 'ffi-rzmq', '~> 0.8.0'
  gem.add_dependency 'multi_json', '~> 1.0.0'
  gem.add_development_dependency "rspec", "~> 2.6.0"
  gem.add_development_dependency "yard", "~> 0.6.7"

  files = FileList["**/*"]
  # Editor and O/S files
  files.exclude ".DS_Store", "*~", "\#*", ".\#*", "*.swp", "*.tmproj", "tmtags"
  # Generated artifacts
  files.exclude "coverage", "rdoc", "pkg", "doc", ".bundle", "*.rbc", ".rvmrc", ".watchr", ".rspec"
  # Project-specific
  files.exclude "Gemfile.lock"
  # Remove directories
  files.exclude {|d| File.directory?(d) }

  gem.files = files.to_a
  gem.test_files = gem.files.grep(/_spec\.rb$/)
end

Rake::GemPackageTask.new(gemspec) do |pkg|
  pkg.need_zip = false
  pkg.need_tar = false
end

task :gem => :gemspec

desc %{Build the gemspec file.}
task :gemspec do
  gemspec.validate
  File.open("#{gemspec.name}.gemspec", 'w'){|f| f.write gemspec.to_ruby }
end

desc %{Release the gem to RubyGems.org}
task :release => :gem do
  system "gem push pkg/#{gemspec.name}-#{gemspec.version}.gem"
end

require 'rspec/core'
require 'rspec/core/rake_task'

desc "Run specs"
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = "spec/**/*_spec.rb"
end

task :default => :spec
