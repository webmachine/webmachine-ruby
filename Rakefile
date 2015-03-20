require "bundler/gem_tasks"

begin
  require 'yard'
  require 'yard/rake/yardoc_task'
  YARD::Rake::YardocTask.new do |doc|
    doc.files = Dir["lib/**/*.rb"] + ['README.md']
    doc.options = ["-m", "markdown"]
  end
rescue LoadError
end

desc "Validate the gemspec file."
task :validate_gemspec do
  Gem::Specification.load("webmachine.gemspec").validate
end

task :build => :validate_gemspec

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

require 'rspec/core/rake_task'

desc "Run specs"
RSpec::Core::RakeTask.new(:spec)

task :default => :spec
