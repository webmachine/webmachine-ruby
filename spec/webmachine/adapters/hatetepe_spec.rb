require "spec_helper"

examples = proc do
  let(:application) { Webmachine::Application.new }
  let(:adapter) do
    server = TCPServer.new('0.0.0.0', 0)
    application.configuration.port = server.addr[1]
    server.close

    described_class.new(application)
  end

  it "inherits from Webmachine::Adapter" do
    adapter.should be_a(Webmachine::Adapter)
  end

  describe "#run" do
    it "starts a server" do
      Hatetepe::Server.should_receive(:start).with(adapter.options) { adapter.shutdown }
      adapter.run
    end
  end

  describe "#call" do
    let :request do
      Hatetepe::Request.new(:get, "/", {}, StringIO.new("hello, world!"))
    end

    it "builds a string-like and enumerable request body" do
      application.dispatcher.should_receive(:dispatch) do |req, res|
        req.body.to_s.should       eq("hello, world!")
        enum_to_s(req.body).should eq("hello, world!")
      end
      adapter.call(request) {}
    end

    shared_examples "enumerable response body" do
      before do
        application.dispatcher.stub(:dispatch) {|_, response| response.body = body }
      end

      it "builds an enumerable response body" do
        adapter.call(request) do |response|
          enum_to_s(response.body).should eq("bye, world!")
        end
      end
    end

    describe "with normal response" do
      let(:body) { "bye, world!" }

      it_behaves_like "enumerable response body"
    end

    describe "with streaming response" do
      let(:body) { proc { "bye, world!" } }

      it_behaves_like "enumerable response body"
    end
  end

  def enum_to_s(enum)
    enum.to_enum.to_a.join
  end
end
