require "spec_helper"
require "support/test_resource"
require "httpclient"

begin
  describe Webmachine::Adapters::Mongrel do
    let(:configuration) { Webmachine::Configuration.default }
    let(:dispatcher) { Webmachine::Dispatcher.new }

    let(:adapter) do
      described_class.new(configuration, dispatcher)
    end

    let(:mongrel_config) { adapter.config }
    let(:server_thread) { Thread.new { mongrel_config.join } }
    let(:client) { HTTPClient.new }

    let(:test_endpoint) { "http://#{configuration.ip}:#{configuration.port}/test" }
    let(:missing_endpoint) { "http://#{configuration.ip}:#{configuration.port}/missing" }

    before do
      dispatcher.add_route ["test"], Test::Resource

      server_thread.join(0.001)
    end

    after do
      mongrel_config.stop
      server_thread.join
    end

    it "inherits from Webmachine::Adapter" do
      adapter.should be_a_kind_of(Webmachine::Adapter)
    end

    it "should proxy requests to webmachine" do
      response = client.get(test_endpoint)
      response.body.should eq("<html><body>testing</body></html>")
    end

    it "should build a string-like request body" do
      dispatcher.should_receive(:dispatch) do |request, response|
        request.body.to_s.should eq("Hello, World!")
      end
      client.post(test_endpoint, "Hello, World!")
    end

    it "should build an enumerable request body" do
      chunks = []
      dispatcher.should_receive(:dispatch) do |request, response|
        request.body.each { |chunk| chunks << chunk }
      end
      client.post(test_endpoint, "Hello, World!")
      chunks.join.should eq("Hello, World!")
    end

    it "should set Server header" do
      response = client.get(test_endpoint)
      response.headers["Server"].should match(/Webmachine/)
      response.headers["Server"].should match(/Mongrel/)
    end

    it "should handle streaming enumerable response bodies" do
      request_headers = { "Accept" => "application/vnd.webmachine.streaming+enum" }
      response = client.get(test_endpoint, {}, request_headers)
      response.body.should eq("Hello,World!")
    end

    it "should handle streaming callable response bodies" do
      request_headers = { "Accept" => "application/vnd.webmachine.streaming+proc" }
      response = client.get(test_endpoint, {}, request_headers)
      response.body.should eq("Stream")
    end
  end
rescue LoadError
  warn "Platform is #{RUBY_PLATFORM}: skipping mongrel adapter spec."
end
