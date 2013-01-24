require 'spec_helper'
require 'webmachine/adapters/rack'
require 'rack'
require 'rack/test'
require 'rack/lint'
require 'support/test_resource'

describe Webmachine::Adapters::Rack do
  include Rack::Test::Methods

  let(:configuration) { Webmachine::Configuration.new('0.0.0.0', 8080, :Rack, {}) }
  let(:dispatcher)    { Webmachine::Dispatcher.new }
  let(:adapter) do
    described_class.new(configuration, dispatcher)
  end
  let(:app) { Rack::Lint.new(adapter) }

  before do
    dispatcher.add_route ['test'], Test::Resource
  end

  it "inherits from Webmachine::Adapter" do
    adapter.should be_a_kind_of(Webmachine::Adapter)
  end

  describe "#run" do
    before do
      configuration.adapter_options[:debug] = true
    end

    it "starts a rack server with the correct options" do
      Rack::Server.should_receive(:start).with(
        :app => adapter,
        :Port => configuration.port,
        :Host => configuration.ip,
        :debug => true
      )

      adapter.run
    end
  end

  it "should proxy request to webmachine" do
    get "/test"
    last_response.status.should == 200
    last_response.original_headers["Content-Type"].should == "text/html"
    last_response.body.should == "<html><body>testing</body></html>"
  end

  it "should build a string-like request body" do
    dispatcher.should_receive(:dispatch) do |request, response|
      request.body.to_s.should eq("Hello, World!")
      response.headers["Content-Type"] = "text/plain"
    end
    request "/test", :method => "GET", :input => "Hello, World!"
  end

  it "should build an enumerable request body" do
    chunks = []
    dispatcher.should_receive(:dispatch) do |request, response|
      request.body.each { |chunk| chunks << chunk }
      response.headers["Content-Type"] = "text/plain"
    end
    request "/test", :method => "GET", :input => "Hello, World!"
    chunks.join.should eq("Hello, World!")
  end

  it "should understand the Content-Type header correctly" do
    header "CONTENT_TYPE", "application/json"
    put "/test"
    last_response.status.should == 204
  end

  it "should set Server header" do
    get "/test"
    last_response.original_headers.should have_key("Server")
  end

  it "should set Set-Cookie header" do
    get "/test"
    # Yes, Rack expects multiple values for a given cookie to be
    # \n separated.
    last_response.original_headers["Set-Cookie"].should == "cookie=monster\nrodeo=clown"
  end

  it "should handle non-success correctly" do
    get "/missing"
    last_response.status.should == 404
    last_response.content_type.should == "text/html"
  end

  it "should handle empty bodies correctly" do
    header "CONTENT_TYPE", "application/json"
    post "/test"
    last_response.status.should == 204
    last_response.original_headers.should_not have_key("Content-Type")
    last_response.original_headers.should_not have_key("Content-Length")
    last_response.body.should == ""
  end

  it "should handle cookies correctly" do
    header "COOKIE", "string=123"
    get "/test"
    last_response.status.should == 200
    last_response.body.should == "<html><body>123</body></html>"
  end

  it "should handle streaming enumerable response bodies" do
    header "ACCEPT", "application/vnd.webmachine.streaming+enum"
    get "/test"
    last_response.status.should == 200
    last_response.original_headers["Transfer-Encoding"].should == "chunked"
    last_response.body.split("\r\n").should == %W{6 Hello, 6 World! 0}
  end

  it "should handle streaming callable response bodies" do
    header "ACCEPT", "application/vnd.webmachine.streaming+proc"
    get "/test"
    last_response.status.should == 200
    last_response.original_headers["Transfer-Encoding"].should == "chunked"
    last_response.body.split("\r\n").should == %W{6 Stream 0}
  end

  it "should receive Content-Type on Not acceptable response" do
    header "ACCEPT", "text/plain"
    get "/test"
    last_response.status.should == 406
    last_response.original_headers.should have_key('Content-Type')
  end
end
