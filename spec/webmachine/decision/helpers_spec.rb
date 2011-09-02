require 'spec_helper'

describe Webmachine::Decision::Helpers do
  subject { Webmachine::Decision::FSM.new(resource, request, response) }
  let(:method) { 'GET' }
  let(:uri) { URI.parse('http://localhost/') }
  let(:headers) { Webmachine::Headers.new }
  let(:body) { '' }
  let(:request) { Webmachine::Request.new(method, uri, headers, body) }
  let(:response) { Webmachine::Response.new }

  def resource_with(&block)
    klass = Class.new(Webmachine::Resource) do
      def to_html; "test resource"; end
    end
    klass.module_eval(&block) if block_given?
    klass.new(request, response)
  end

  let(:resource) { resource_with }

  describe "#encode_body" do
    before { subject.run }

    context "with a String body" do
      before { response.body = '<body></body>' }

      it "does not modify the response body" do
        subject.encode_body
        String.should === response.body
      end
    end

    context "with an Enumerable body" do
      before { response.body = ['one', 'two'] }

      it "wraps the response body in an EnumerableEncoder" do
        subject.encode_body
        Webmachine::EnumerableEncoder.should === response.body
      end
    end

    context "with a callable body" do
      before { response.body = Proc.new { 'proc' } }

      it "wraps the response body in a CallableEncoder" do
        subject.encode_body
        Webmachine::CallableEncoder.should === response.body
      end
    end
  end
end
