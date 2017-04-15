require "bundler/setup"
Bundler.require :default, :test, :webservers
require 'logger'
require 'webmachine/adapters/rack'

class NullLogger < Logger
  def add(severity, message=nil, progname=nil, &block)
  end
end

RSpec.configure do |config|
  config.mock_with :rspec
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
  config.formatter = :documentation if ENV['CI']
  if defined?(::Java)
    config.seed = Time.now.utc
  else
    config.order = :random
  end

  config.before(:suite) do
    options = {
      :Logger => NullLogger.new(STDERR),
      :AccessLog => []
    }
    Webmachine::Adapters::WEBrick::DEFAULT_OPTIONS.merge! options
    Webmachine::Adapters::Rack::DEFAULT_OPTIONS.merge! options if defined?(Webmachine::Adapters::Rack)
  end
end

# For use in specs that need a fully initialized resource
shared_context "default resource" do
  let(:method) { 'GET' }
  let(:uri) { URI.parse("http://localhost/") }
  let(:headers) { Webmachine::Headers.new }
  let(:body) { "" }
  let(:request) { Webmachine::Request.new(method, uri, headers, body) }
  let(:response) { Webmachine::Response.new }

  let(:resource_class) do
    Class.new(Webmachine::Resource) do
      def to_html
        "<html><body>Hello, world!</body></html>"
      end
    end
  end
  let(:resource) { resource_class.new(request, response) }
end
