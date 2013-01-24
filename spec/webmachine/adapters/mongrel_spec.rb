require "spec_helper"
require "support/test_resource"
require "net/http"

begin
  describe Webmachine::Adapters::Mongrel do
    let(:configuration) { Webmachine::Configuration.default }
    let(:dispatcher) { Webmachine::Dispatcher.new }

    let(:adapter) do
      described_class.new(configuration, dispatcher)
    end

    let(:server_thread) { Thread.new { adapter.run } }
    let(:client) { Net::HTTP.new(configuration.ip, configuration.port) }

    let(:test_endpoint) { "http://#{configuration.ip}:#{configuration.port}/test" }
    let(:missing_endpoint) { "http://#{configuration.ip}:#{configuration.port}/missing" }

    before do
      dispatcher.add_route ["test"], Test::Resource

      server_thread.join(0.001)
    end

    after do
      adapter.shutdown
      server_thread.join
    end

    it "inherits from Webmachine::Adapter" do
      adapter.should be_a_kind_of(Webmachine::Adapter)
    end

    it "should proxy requests to webmachine" do
      response = client.request(Net::HTTP::Get.new("/test"))
      response.body.should eq("<html><body>testing</body></html>")
    end

    it "should build a string-like request body" do
      request = Net::HTTP::Post.new("/test")
      request.body = "Hello, World!"
      dispatcher.should_receive(:dispatch) do |request, response|
        request.body.to_s.should eq("Hello, World!")
      end
      client.request(request)
    end

    it "should build an enumerable request body" do
      request = Net::HTTP::Post.new("/test")
      request.body = "Hello, World!"
      chunks = []
      dispatcher.should_receive(:dispatch) do |request, response|
        request.body.each { |chunk| chunks << chunk }
      end
      client.request(request)
      chunks.join.should eq("Hello, World!")
    end

    it "should set Server header" do
      response = client.request(Net::HTTP::Get.new("/test"))
      response["Server"].should match(/Webmachine/)
      response["Server"].should match(/Mongrel/)
    end

    it "should handle streaming enumerable response bodies" do
      request = Net::HTTP::Get.new("/test")
      request["Accept"] = "application/vnd.webmachine.streaming+enum"
      response = client.request(request)
      response.body.should eq("Hello,World!")
    end

    it "should handle streaming callable response bodies" do
      request = Net::HTTP::Get.new("/test")
      request["Accept"] = "application/vnd.webmachine.streaming+proc"
      response = client.request(request)
      response.body.should eq("Stream")
    end
  end
rescue LoadError
  warn "Platform is #{RUBY_PLATFORM}: skipping mongrel adapter spec."
end
