require 'webmachine'

class HelloResource < Webmachine::Resource
  def last_modified
    File.mtime(__FILE__)
  end

  def encodings_provided
    {'gzip' => :encode_gzip, 'identity' => :encode_identity}
  end

  def to_html
    '<html><head><title>Hello from Webmachine</title></head><body>Hello, world!</body></html>'
  end
end

App = Webmachine::Application.new do |app|
  app.routes do
    add [], HelloResource
  end
end

App.run
