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

  let(:configuration) { Webmachine::Configuration.new('0.0.0.0', 8080, :Rack, {}) }
  let(:dispatcher)    { Webmachine::Dispatcher.new }
  let(:adapter) do
    described_class.new(configuration, dispatcher)
  end

  subject { adapter }

  before do
    dispatcher.add_route ['test'], Test::Resource
  end

  describe "#initialize" do
    it "stores the provided configuration" do
      adapter.configuration.should eql configuration
    end

    it "stores the provided dispatcher" do
      adapter.dispatcher.should eql dispatcher
    end
  end

  describe ".run" do
    it "creates a new adapter and runs it" do
      adapter = mock(described_class)

      described_class.should_receive(:new).
        with(configuration, dispatcher).
        and_return(adapter)

      adapter.should_receive(:run)

      described_class.run(configuration, dispatcher)
    end
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

  it "should set Server header" do
    code, headers, body = subject.call(env)
    headers.should have_key "Server"
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
end
