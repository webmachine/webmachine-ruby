require 'spec_helper'

describe Webmachine::Decision::Flow do
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

  describe "#b13 (Service Available?)" do
    let(:resource) do
      resource_with do
        attr_accessor :available
        def service_available?; @available; end
      end
    end

    it "should respond with 503 when the service is unavailable" do
      resource.available = false
      subject.run
      response.code.should == 503
    end
  end

  describe "#b12 (Known method?)" do
    let(:resource) do
      resource_with do
        def known_methods; ['HEAD']; end
      end
    end

    it "should respond with 501 when the method is unknown" do
      subject.run
      response.code.should == 501
    end
  end

  describe "#b11 (URI too long?)" do
    let(:resource) do
      resource_with do
        def uri_too_long?(uri); true; end
      end
    end

    it "should respond with 414 when the URI is too long" do
      subject.run
      response.code.should == 414
    end
  end

  describe "#b10 (Method allowed?)" do
    let(:resource) do
      resource_with do
        def allowed_methods; ['POST']; end
      end
    end

    it "should respond with 405 when the method is not allowed" do
      subject.run
      response.code.should == 405
    end
  end

  describe "#b9 (Malformed request?)" do
    let(:resource) { resource_with { def malformed_request?; true; end } }

    it "should respond with 400 when the request is malformed" do
      subject.run
      response.code.should == 400
    end

    context "when the Content-MD5 header is present" do
      let(:resource) do
        resource_with do
          def allowed_methods; ['POST']; end;
          def process_post; true; end;
          attr_accessor :validation
          def validate_content_checksum; @validation; end
        end
      end

      let(:method) { "POST" }
      let(:body) { "This is the body." }
      let(:headers) { Webmachine::Headers["Content-Type" => "text/plain"] }

      it "should respond with 400 when the request body does not match the header" do
        headers['Content-MD5'] = "thiswillnotmatchthehash"
        subject.run
        response.code.should == 400
      end

      it "should respond with 400 when the resource invalidates the checksum" do
        resource.validation = false
        headers['Content-MD5'] = "thiswillnotmatchthehash"
        subject.run
        response.code.should == 400
      end

      it "should not respond with 400 when the resource validates the checksum" do
        resource.validation = true
        headers['Content-MD5'] = "thiswillnotmatchthehash"
        subject.run
        response.code.should_not == 400
      end

      it "should respond with the given code when the resource returns a code while validating" do
        resource.validation = 500
        headers['Content-MD5'] = "thiswillnotmatchthehash"
        subject.run
        response.code.should == 500
      end
    end
  end

  describe "#b8 (Authorized?)" do
    let(:resource) { resource_with { attr_accessor :auth; def is_authorized?(header); @auth; end } }

    it "should reply with 401 when the client is unauthorized" do
      resource.auth = false
      subject.run
      response.code.should == 401
    end

    it "should reply with 401 when the resource gives a challenge" do
      resource.auth = "Basic realm=Webmachine"
      subject.run
      response.code.should == 401
      response.headers['WWW-Authenticate'].should == "Basic realm=Webmachine"
    end

    it "should halt with the given code when the resource returns a status code" do
      resource.auth = 400
      subject.run
      response.code.should == 400
    end

    it "should not reply with 401 when the client is authorized" do
      resource.auth = true
      subject.run
      response.code.should_not == 401
    end
  end

  describe "#b7 (Forbidden?)" do
    let(:resource) { resource_with { attr_accessor :forbid; def forbidden?; @forbid; end } }

    it "should reply with 403 when the request is forbidden" do
      resource.forbid = true
      subject.run
      response.code.should == 403
    end

    it "should not reply with 403 when the request is permitted" do
      resource.forbid = false
      subject.run
      response.code.should_not == 403
    end

    it "should halt with the given code when the resource returns a status code" do
      resource.forbid = 400
      subject.run
      response.code.should == 400
    end
  end

  describe "#b6 (Unsupported Content-* header?)" do
    let(:resource) do
      resource_with do
        def valid_content_headers?(contents)
          contents['Content-Fail'].nil?
        end
      end
    end

    it "should reply with 501 when an invalid Content-* header is present" do
      headers['Content-Fail'] = "yup"
      subject.run
      response.code.should == 501
    end

    it "should not reply with 501 when all Content-* headers are valid" do
      subject.run
      response.code.should_not == 501
    end
  end

  describe "#b5 (Known Content-Type?)" do
    let(:method) { "POST" }
    let(:body) { "This is the body." }
    let(:resource) do
      resource_with do
        def known_content_type?(type) type !~ /unknown/; end;
        def process_post; true; end
        def allowed_methods; %w{POST}; end
      end
    end

    before { headers['Content-Length'] = body.length.to_s }

    it "should reply with 415 when the Content-Type is unknown" do
      headers['Content-Type'] = "application/x-unknown-type"
      subject.run
      response.code.should == 415
    end

    it "should not reply with 415 when the Content-Type is known" do
      headers['Content-Type'] = "text/plain"
      subject.run
      response.code.should_not == 415
    end
  end
end
