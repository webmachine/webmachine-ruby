require "spec_helper"

examples = proc do
  let(:configuration) { Webmachine::Configuration.default              }
  let(:dispatcher)    { Webmachine::Dispatcher.new                     }
  let(:adapter)       { described_class.new(configuration, dispatcher) }

  it "inherits from Webmachine::Adapter" do
    adapter.should be_a(Webmachine::Adapter)
  end

  describe "#run" do
    it "starts a server" do
      Hatetepe::Server.should_receive(:start).with(adapter.options) { EM.stop }
      adapter.run
    end
  end

  describe "#call" do
    let :request do
      Hatetepe::Request.new(:get, "/", {}, StringIO.new("hello, world!"))
    end

    it "builds a string-like and enumerable request body" do
      dispatcher.should_receive(:dispatch) do |req, res|
        req.body.to_s.should       eq("hello, world!")
        enum_to_s(req.body).should eq("hello, world!")
      end
      adapter.call(request) {}
    end

    shared_examples "enumerable response body" do
      before do
        dispatcher.stub(:dispatch) {|_, response| response.body = body }
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

if RUBY_VERSION >= "1.9"
  describe Webmachine::Adapters::Hatetepe, &examples
end
