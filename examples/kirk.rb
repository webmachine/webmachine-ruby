require 'webmachine'
require 'webmachine/adapters/kirk'

class HelloResource < Webmachine::Resource
  def last_modified
    File.mtime(__FILE__)
  end

  def encodings_provided
    { "gzip" => :encode_gzip, "identity" => :encode_identity }
  end

  def to_html
    "<html><head><title>Hello from Webmachine</title></head><body>Hello, world!</body></html>"
  end
end

Webmachine::Dispatcher.add_route([], HelloResource)

Webmachine.configure do |config|
  config.ip = '127.0.0.1'
  config.port = 5000
  config.adapter = :Kirk
end

Webmachine.run
