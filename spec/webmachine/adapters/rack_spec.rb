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

  it "should set Server header" do
    response = get "/test"
    response["Server"].should match(/Webmachine/)
    response["Server"].should match(/Rack/)
  end

  # FIXME: The following tests are copies of the lint tests.
  # I don't want to use the lint tests because that would be unnecessarily slower.
  # It would be nice if the examples could be combined, so they don't need to be kept in sync.

  it "provides a string-like request body" do
    header "Content-Type", "test/request.stringbody"
    response = put "/test", "Hello, World!"
    response.headers["Content-Length"].should eq("21")
    response.body.should eq("String: Hello, World!")
  end

  it "provides an enumerable request body" do
    header "Content-Type", "test/request.enumbody"
    response = put "/test", "Hello, World!"
    response.headers["Content-Length"].should eq("19")
    response.body.should eq("Enum: Hello, World!")
  end

  it "handles missing pages" do
    response = get "/missing"
    response.status.should eq(404)
    response["Content-Type"].should eq("text/html")
  end

  it "handles empty response bodies" do
    response = post "/test"
    response.status.should eq(204)
    response["Content-Type"].should be_nil
    response["Content-Length"].should be_nil
    response.body.should be_empty
  end

  it "handles string response bodies" do
    header "Accept", "test/response.stringbody"
    response = get "/test"
    response.headers["Content-Length"].should eq("20")
    response.body.should eq("String response body")
  end

  it "handles enumerable response bodies" do
    header "Accept", "test/response.enumbody"
    response = get "/test"
    response.headers["Transfer-Encoding"].should eq("chunked")
    response.body.split("\r\n").should eq(["b", "Enumerable ", "d", "response body", "0"])
  end

  it "handles proc response bodies" do
    header "Accept", "test/response.procbody"
    response = get "/test"
    response.headers["Transfer-Encoding"].should eq("chunked")
    response.body.split("\r\n").should eq(["12", "Proc response body", "0"])
  end

  it "handles fiber response bodies" do
    header "Accept", "test/response.fiberbody"
    response = get "/test"
    response.headers["Transfer-Encoding"].should eq("chunked")
    response.body.split("\r\n").should eq(["6", "Fiber ", "9", "response ", "4", "body", "0"])
  end

  it "handles request cookies" do
    header "Accept", "test/response.cookies"
    header "Cookie", "echo=echocookie"
    response = get "/test"
    response.body.should eq("echocookie")
  end

  it "handles response cookies" do
    header "Accept", "test/response.cookies"
    response = get "/test"
    response.headers["Set-Cookie"].should eq("cookie=monster\nrodeo=clown")
  end
end
