require 'spec_helper'
require 'webmachine/adapters/rack'
require 'rack'

module Test
  class Resource < Webmachine::Resource
    def to_html
      "<html><body>testing</body></html>"
    end
  end
end

describe Webmachine::Adapters::Rack do
  let(:adapter) { described_class }

  let(:env) do
    { "REQUEST_METHOD"    => "GET",
      "SCRIPT_NAME"       => "",
      "PATH_INFO"         => "/test",
      "QUERY_STRING"      => "",
      "SERVER_NAME"       => "test.server",
      "SERVER_PORT"       => 8080,
      "rack.version"      => Rack::VERSION,
      "rack.url_scheme"   => "http",
      "rack.input"        => StringIO.new,
      "rack.errors"       => StringIO.new,
      "rack.multithread"  => false,
      "rack.multiprocess" => true,
      "rack.run_once"     => false }
  end

  before do
    Webmachine::Dispatcher.reset
    Webmachine::Dispatcher.add_route ['test'], Test::Resource
  end

  it "should proxy request to webmachine" do
    code, headers, body = adapter.new.call(env)
    code.should == 200
    headers["Content-Type"].should == "text/html"
    body.should include "<html><body>testing</body></html>"
  end

  it "should set Server header" do
    code, headers, body = adapter.new.call(env)
    headers.should have_key "Server"
  end

  it "should handle non-success correctly" do
    env["PATH_INFO"] = "/missing"
    code, headers, body = adapter.new.call(env)
    code.should == 404
    headers["Content-Type"].should == "text/html"
  end

  it "should handle empty bodies correctly" do
    env["HTTP_ACCEPT"] = "application/json"
    code, headers, body = adapter.new.call(env)
    code.should == 406
    headers.should_not have_key "Content-Type"
    headers.should_not have_key "Content-Length"
    body.should == []
  end
end
