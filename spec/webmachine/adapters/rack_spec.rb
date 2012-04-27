require 'spec_helper'
require 'webmachine/adapters/rack'
require 'rack'
require 'rack/test'

module Test
  class Resource < Webmachine::Resource
    def allowed_methods
      ["GET", "PUT", "POST"]
    end

    def content_types_accepted
      [["application/json", :from_json]]
    end

    def content_types_provided
      [["text/html", :to_html], ["application/vnd.webmachine.streaming", :to_stream]]
    end

    def process_post
      true
    end

    def to_html
      response.set_cookie('cookie', 'monster')
      response.set_cookie('rodeo', 'clown')
      "<html><body>#{request.cookies['string'] || 'testing'}</body></html>"
    end

    def to_stream
      %w{Hello, World!}
    end

    def from_json; end
  end
end

describe Webmachine::Adapters::Rack do
  include Rack::Test::Methods

  let(:configuration) { Webmachine::Configuration.new('0.0.0.0', 8080, :Rack, {}) }
  let(:dispatcher)    { Webmachine::Dispatcher.new }
  let(:adapter) do
    described_class.new(configuration, dispatcher)
  end
  let(:app) { adapter }

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
    last_response.headers["Content-Type"].should == "text/html"
    last_response.body.should == "<html><body>testing</body></html>"
  end

  it "should build a string-like request body" do
    dispatcher.should_receive(:dispatch) do |request, response|
      request.body.to_s.should eq("Hello, World!")
    end
    request "/test", :method => "GET", :input => "Hello, World!"
  end

  it "should build an enumerable request body" do
    chunks = []
    dispatcher.should_receive(:dispatch) do |request, response|
      request.body.each { |chunk| chunks << chunk }
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
    last_response.headers.should have_key("Server")
  end

  it "should set Set-Cookie header" do
    get "/test"
    # Yes, Rack expects multiple values for a given cookie to be
    # \n separated.
    last_response.headers["Set-Cookie"].should == "cookie=monster\nrodeo=clown"
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
    last_response.headers.should_not have_key("Content-Type")
    last_response.headers.should_not have_key("Content-Length")
    last_response.body.should == ""
  end

  it "should handle cookies correctly" do
    header "COOKIE", "string=123"
    get "/test"
    last_response.status.should == 200
    last_response.body.should == "<html><body>123</body></html>"
  end

  it "should handle streaming response bodies" do
    header "ACCEPT", "application/vnd.webmachine.streaming"
    get "/test"
    last_response.status.should == 200
    last_response.body.should == "Hello,World!"
  end
end
