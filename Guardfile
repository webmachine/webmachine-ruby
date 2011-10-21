gemset = ENV['RVM_GEMSET'] || 'webmachine'
gemset = "@#{gemset}" unless gemset.to_s == ''

rvms = %W[ 1.8.7 1.9.2 jruby rbx ].map {|v| "#{v}#{gemset}" }

guard 'rspec', :cli => "--color --profile", :growl => true, :rvm => rvms do
  watch(%r{^lib/webmachine/locale/.+$}) { "spec" }
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$}){ |m| "spec/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb') { "spec" }
end
