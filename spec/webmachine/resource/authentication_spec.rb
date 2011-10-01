require 'spec_helper'

describe Webmachine::Resource::Authentication do
  subject { Webmachine::Decision::FSM.new(resource, request, response) }
  let(:method) { 'GET' }
  let(:uri) { URI.parse("http://localhost/") }
  let(:headers) { Webmachine::Headers.new }
  let(:body) { "" }
  let(:request) { Webmachine::Request.new(method, uri, headers, body) }
  let(:response) { Webmachine::Response.new }

  def resource_with(&block)
    klass = Class.new(Webmachine::Resource) do
      def to_html; "test resource"; end
    end
    klass.module_eval(&block) if block_given?
    klass.new(request, response)
  end

  describe "Basic authentication" do
    let(:resource) do
      resource_with do
        include Webmachine::Resource::Authentication
        attr_accessor :realm
        def is_authorized?(auth)
          basic_auth(auth, @realm || "Webmachine") {|u,p| u == "webmachine" && p == "http" }
        end
      end
    end
    
    context "when no authorization is sent by the client" do
      it "should reply with a 401 Unauthorized and a WWW-Authenticate header using Basic" do
        subject.run
        response.code.should == 401
        response.headers['WWW-Authenticate'].should == 'Basic realm="Webmachine"'
      end

      it "should use the specified realm in the WWW-Authenticate header" do
        resource.realm = "My App"
        subject.run
        response.headers['WWW-Authenticate'].should == 'Basic realm="My App"'
      end
    end

    context "when the client sends invalid authorization" do
      before do
        headers['Authorization'] = "Basic " + ["invalid:auth"].pack('m*').chomp
      end
      
      it "should reply with a 401 Unauthorized and a WWW-Authenticate header using Basic" do
        subject.run
        response.code.should == 401
        response.headers['WWW-Authenticate'].should == 'Basic realm="Webmachine"'
      end      
    end

    context "when the client sends valid authorization" do
      before do
        headers['Authorization'] = "Basic " + ["webmachine:http"].pack('m*').chomp
      end

      it "should not reply with 401 Unauthorized" do
        subject.run
        response.code.should_not == 401
      end
    end
  end
end
