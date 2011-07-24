gemset = ENV['RVM_GEMSET'] || 'webmachine'
gemset = "@#{gemset}" unless gemset.to_s == ''

rvms = %W[ 1.8.7 1.9.2 rbx jruby ].map {|v| "#{v}#{gemset}" }

guard 'rspec', :rvm => rvms do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$}){ |m| "spec/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb') { "spec" }
end
