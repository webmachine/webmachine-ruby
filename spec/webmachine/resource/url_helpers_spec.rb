require 'spec_helper'

describe Webmachine::Resource::UrlHelpers do
  let(:method) { 'GET' }
  let(:uri) { URI.parse("http://localhost/") }
  let(:headers) { Webmachine::Headers.new }
  let(:body) { "" }
  let(:dispatcher) { Webmachine::Dispatcher.new }
  let(:request) { Webmachine::Request.new(method, uri, headers, body) }
  let(:response) { Webmachine::Response.new }

  let(:resource) do
    Class.new(Webmachine::Resource) do
      def to_html; "hello world!"; end
    end
  end
  let(:resource2) do
    Class.new(Webmachine::Resource) do
      def to_html; "goodbye, cruel world"; end
    end
  end

  describe "#url_for" do
    before(:all) do
      dispatcher.add_route ["world", :world_id], resource
      dispatcher.add_route ["cruel"], resource2
    end

    it "pulls the url from the dispatcher" do
      dispatcher.should_receive(:url_for).with(resource, {:world_id => 1})
      resource.new(dispatcher, request, response).url_for(resource, :world_id => 1)
    end
  end
end
