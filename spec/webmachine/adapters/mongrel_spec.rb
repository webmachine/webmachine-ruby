require "spec_helper"

begin
  describe Webmachine::Adapters::Mongrel do
    let(:configuration) { Webmachine::Configuration.default }
    let(:dispatcher) { Webmachine::Dispatcher.new }

    let(:adapter) do
      described_class.new(configuration, dispatcher)
    end

    it "inherits from Webmachine::Adapter" do
      adapter.should be_a_kind_of(Webmachine::Adapter)
    end

    it "implements #run" do
      adapter.should respond_to(:run)
    end

    describe "request handler" do
      let(:request_params) do
        {
          "REQUEST_METHOD" => "GET",
          "REQUEST_URI" => "http://www.example.com/test?query=string"
        }
      end
      let(:request_body) { StringIO.new("Hello, World!") }
      let(:mongrel_request) { stub(:params => request_params, :body => request_body) }
      let(:mongrel_response) { stub.as_null_object }

      subject { Webmachine::Adapters::Mongrel::Handler.new(dispatcher) }

      it "should build a string-like request body" do
        dispatcher.should_receive(:dispatch) do |request, response|
          request.body.to_s.should eq("Hello, World!")
        end
        subject.process(mongrel_request, mongrel_response)
      end

      it "should build an enumerable request body" do
        chunks = []
        dispatcher.should_receive(:dispatch) do |request, response|
          request.body.each { |chunk| chunks << chunk }
        end
        subject.process(mongrel_request, mongrel_response)
        chunks.join.should eq("Hello, World!")
      end
    end

    it "can run" do
      expect {
        adapter.run
      }.not_to raise_error
    end
  end
rescue LoadError
  warn "Platform is #{RUBY_PLATFORM}: skipping mongrel adapter spec."
end
