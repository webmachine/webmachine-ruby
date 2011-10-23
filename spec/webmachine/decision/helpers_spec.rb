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

  describe "accepting request bodies" do
    let(:resource) do
      resource_with do
        def initialize
          @accepted, @result = [], true
        end
        attr_accessor :accepted, :result
        def content_types_accepted
          (accepted || []).map {|t| Array === t ? t : [t, :accept_doc] }
        end
        def accept_doc; result; end
      end
    end

    it "should return 415 when no types are accepted" do
      subject.accept_helper.should == 415
    end

    it "should return 415 when the posted type is not acceptable" do
      resource.accepted = %W{application/json}
      headers['Content-Type'] = "text/xml"
      subject.accept_helper.should == 415
    end

    it "should call the method for the first acceptable type, taking into account params" do
      resource.accepted = ["application/json;v=3", ["application/json", :other]]
      resource.should_receive(:other).and_return(true)
      headers['Content-Type'] = 'application/json;v=2'
      subject.accept_helper.should be_true
    end
  end

  describe "#encode_body" do
    before { subject.run }

    context "with a String body" do
      before { response.body = '<body></body>' }

      it "does not modify the response body" do
        subject.encode_body
        String.should === response.body
      end

      it "sets the Content-Length header in the response" do
        subject.encode_body
        response.headers['Content-Length'].should == response.body.bytesize.to_s
      end
    end

    shared_examples_for "a non-String body" do
      it "does not set the Content-Length header in the response" do
        subject.encode_body
        response.headers.should_not have_key('Content-Length')
      end

      it "sets the Transfer-Encoding response header to chunked" do
        subject.encode_body
        response.headers['Transfer-Encoding'].should == 'chunked'
      end
    end

    context "with an Enumerable body" do
      before { response.body = ['one', 'two'] }

      it "wraps the response body in an EnumerableEncoder" do
        subject.encode_body
        Webmachine::EnumerableEncoder.should === response.body
      end

      it_should_behave_like "a non-String body"
    end

    context "with a callable body" do
      before { response.body = Proc.new { 'proc' } }

      it "wraps the response body in a CallableEncoder" do
        subject.encode_body
        Webmachine::CallableEncoder.should === response.body
      end

      it_should_behave_like "a non-String body"
    end

    context "with a Fiber body" do
      before { response.body = Fiber.new { Fiber.yield "foo" } }

      it "wraps the response body in a FiberEncoder" do
        subject.encode_body
        Webmachine::FiberEncoder.should === response.body
      end

      it_should_behave_like "a non-String body"
    end
  end
end
