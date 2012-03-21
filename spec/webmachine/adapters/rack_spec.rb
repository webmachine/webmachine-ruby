require 'spec_helper'
require 'webmachine/adapters/rack'
require 'rack'

module Test
  class Resource < Webmachine::Resource
    def allowed_methods
      ["GET", "PUT"]
    end

    def content_types_accepted
      [["application/json", :from_json]]
    end

    def to_html
      response.set_cookie('cookie', 'monster')
      response.set_cookie('rodeo', 'clown')
      "<html><body>#{request.cookies['string'] || 'testing'}</body></html>"
    end

    def from_json; end
  end
end

describe Webmachine::Adapters::Rack do
  let(:env) do
    { "REQUEST_METHOD"    => "GET",
      "SCRIPT_NAME"       => "",
      "PATH_INFO"         => "/test",
      "QUERY_STRING"      => "",
      "SERVER_NAME"       => "test.server",
      "SERVER_PORT"       => 8080,
      "rack.version"      => Rack::VERSION,
      "rack.url_scheme"   => "http",
      "rack.input"        => StringIO.new("Hello, World!"),
      "rack.errors"       => StringIO.new,
      "rack.multithread"  => false,
      "rack.multiprocess" => true,
      "rack.run_once"     => false }
  end

  let(:configuration) { Webmachine::Configuration.new('0.0.0.0', 8080, :Rack, {}) }
  let(:dispatcher)    { Webmachine::Dispatcher.new }
  let(:adapter) do
    described_class.new(configuration, dispatcher)
  end

  subject { adapter }

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
    code, headers, body = subject.call(env)
    code.should == 200
    headers["Content-Type"].should == "text/html"
    body.should include "<html><body>testing</body></html>"
  end

  it "should build a string-like request body" do
    dispatcher.should_receive(:dispatch) do |request, response|
      request.body.to_s.should eq("Hello, World!")
    end
    subject.call(env)
  end

  it "should build an enumerable request body" do
    chunks = []
    dispatcher.should_receive(:dispatch) do |request, response|
      request.body.each { |chunk| chunks << chunk }
    end
    subject.call(env)
    chunks.join.should eq("Hello, World!")
  end

  it "should understand the Content-Type header correctly" do
    env["REQUEST_METHOD"] = "PUT"
    env["CONTENT_TYPE"] = "application/json"
    code, headers, body = subject.call(env)
    code.should == 204
  end

  it "should set Server header" do
    code, headers, body = subject.call(env)
    headers.should have_key "Server"
  end

  it "should set Set-Cookie header" do
    code, headers, body = subject.call(env)
    headers.should have_key "Set-Cookie"
    # Yes, Rack expects multiple values for a given cookie to be
    # \n separated.
    headers["Set-Cookie"].should == "cookie=monster\nrodeo=clown"
  end

  it "should handle non-success correctly" do
    env["PATH_INFO"] = "/missing"
    code, headers, body = subject.call(env)
    code.should == 404
    headers["Content-Type"].should == "text/html"
  end

  it "should handle empty bodies correctly" do
    env["HTTP_ACCEPT"] = "application/json"
    code, headers, body = subject.call(env)
    code.should == 406
    headers.should_not have_key "Content-Type"
    headers.should_not have_key "Content-Length"
    body.should == []
  end

  it "should handle cookies correctly" do
    env["HTTP_COOKIE"] = "string=123"
    code, headers, body = subject.call(env)
    code.should == 200
    body.should include "<html><body>123</body></html>"
  end
end
