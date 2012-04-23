require 'rubygems'
require 'rubygems/package_task'

begin
  require 'yard'
  require 'yard/rake/yardoc_task'
  YARD::Rake::YardocTask.new do |doc|
    doc.files = Dir["lib/**/*.rb"] + ['README.md']
    doc.options = ["-m", "markdown"]
  end
rescue LoadError
end

def gemspec
  $webmachine_gemspec ||= Gem::Specification.load("webmachine.gemspec")
end

Gem::PackageTask.new(gemspec) do |pkg|
  pkg.need_zip = false
  pkg.need_tar = false
end

task :gem => :gemspec

desc %{Validate the gemspec file.}
task :gemspec do
  gemspec.validate
end

desc %{Release the gem to RubyGems.org}
task :release => :gem do
  system "gem push pkg/#{gemspec.name}-#{gemspec.version}.gem"
end

desc "Cleans up white space in source files"
task :clean_whitespace do
  no_file_cleaned = true

  Dir["**/*.rb"].each do |file|
    contents = File.read(file)
    cleaned_contents = contents.gsub(/([ \t]+)$/, '')
    unless cleaned_contents == contents
      no_file_cleaned = false
      puts " - Cleaned #{file}"
      File.open(file, 'w') { |f| f.write(cleaned_contents) }
    end
  end

  if no_file_cleaned
    puts "No files with trailing whitespace found"
  end
end

require 'rspec/core'
require 'rspec/core/rake_task'

desc "Run specs"
RSpec::Core::RakeTask.new(:spec)

task :default => :spec
