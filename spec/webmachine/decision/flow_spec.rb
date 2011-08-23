require 'spec_helper'

describe Webmachine::Decision::Flow do
  subject { Webmachine::Decision::FSM.new(resource, request, response) }
  let(:method) { 'GET' }
  let(:uri) { URI.parse("http://localhost/") }
  let(:headers) { Webmachine::Headers.new }
  let(:body) { "" }
  let(:request) { Webmachine::Request.new(method, uri, headers, body) }
  let(:response) { Webmachine::Response.new }
  let(:default_resource) { resource_with }
  let(:missing_resource) { missing_resource_with }

  def resource_with(&block)
    klass = Class.new(Webmachine::Resource) do
      def to_html; "test resource"; end
    end
    klass.module_eval(&block) if block_given?
    klass.new(request, response)
  end

  def missing_resource_with(&block)
    resource_with do
      def resource_exists?; false; end
      self.module_eval(&block) if block
    end
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
      response.headers['Allow'].should == "POST"
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

  describe "#b4 (Request entity too large?)" do
    let(:resource) do
      resource_with do
        def allowed_methods; %w{POST}; end
        def process_post; true; end
        def valid_entity_length?(length); length.to_i < 100; end
      end
    end
    let(:method) { "POST" }
    before { headers['Content-Type'] = "text/plain"; headers['Content-Length'] = body.size.to_s }

    context "when the request body is too large" do
      let(:body) { "Big" * 100 }
      it "should reply with 413" do
        subject.run
        response.code.should == 413
      end
    end

    context "when the request body is not too large" do
      let(:body) { "small" }

      it "should not reply with 413" do
        subject.run
        response.code.should_not == 413
      end
    end
  end

  describe "#b3 (OPTIONS?)" do
    let(:method){ "OPTIONS" }
    let(:resource){ resource_with { def allowed_methods; %w[GET HEAD OPTIONS]; end } }
    it "should reply with 200 when the request method is OPTIONS" do
      subject.run
      response.code.should == 200
    end
  end

  describe "#c3, #c4 (Acceptable media types)" do
    let(:resource) { default_resource }
    context "when the Accept header exists" do
      it "should reply with 406 when the type is unacceptable" do
        headers['Accept'] = "text/plain"
        subject.run
        response.code.should == 406
      end

      it "should not reply with 406 when the type is acceptable" do
        headers['Accept'] = "text/*"
        subject.run
        response.code.should_not == 406
        response.headers['Content-Type'].should == "text/html"
      end
    end

    context "when the Accept header does not exist" do
      it "should not negotiate a media type" do
        headers['Accept'].should be_nil
        subject.should_not_receive(:c4)
        subject.run
        response.headers['Content-Type'].should == 'text/html'
      end
    end
  end

  describe "#d4, #d5 (Acceptable languages)" do
    let(:resource) { resource_with { def languages_provided; %w{en-US fr}; end } }
    context "when the Accept-Language header exists" do
      it "should reply with 406 when the language is unacceptable" do
        headers['Accept-Language'] = "es, de"
        subject.run
        response.code.should == 406
      end

      it "should not reply with 406 when the language is acceptable" do
        headers['Accept-Language'] = "en-GB, en;q=0.7"
        subject.run
        response.code.should_not == 406
        response.headers['Content-Language'].should == "en-US"
      end
    end

    context "when the Accept-Language header is absent" do
      it "should not negotiate the language" do
        headers['Accept-Language'].should be_nil
        subject.should_not_receive(:d5)
        subject.run
        response.headers['Content-Language'].should == 'en-US'
      end
    end
  end

  describe "#e5, #e6 (Acceptable charsets)" do
    let(:resource) do
      resource_with do
        def charsets_provided
          [["iso8859-1", :to_iso],["utf-8", :to_utf]];
        end
        def to_iso(chunk); chunk; end
        def to_utf(chunk); chunk; end
      end
    end

    context "when the Accept-Charset header exists" do
      it "should reply with 406 when the charset is unacceptable" do
        headers['Accept-Charset'] = "utf-16"
        subject.run
        response.code.should == 406
      end

      it "should not reply with 406 when the charset is acceptable" do
        headers['Accept-Charset'] = "iso8859-1"
        subject.run
        response.code.should_not == 406
        response.headers['Content-Type'].should == "text/html;charset=iso8859-1"
      end
    end

    context "when the Accept-Charset header is absent" do
      it "should not negotiate the language" do
        headers['Accept-Charset'].should be_nil
        subject.should_not_receive(:e6)
        subject.run
        response.headers['Content-Type'].should == 'text/html;charset=iso8859-1'
      end
    end
  end

  describe "#f6, #f7 (Acceptable encodings)" do
    let(:resource) do
      resource_with do
        def encodings_provided
          super.merge("gzip" => :encode_gzip)
        end
      end
    end

    context "when the Accept-Encoding header is present" do
      it "should reply with 406 if the encoding is unacceptable" do
        headers['Accept-Encoding'] = 'deflate, identity;q=0.0'
        subject.run
        response.code.should == 406
      end

      it "should not reply with 406 if the encoding is acceptable" do
        headers['Accept-Encoding'] = 'gzip, deflate'
        subject.run
        response.code.should_not == 406
        response.headers['Content-Encoding'].should == 'gzip'
        # It should be compressed
        response.body.should_not == 'test resource'
      end
    end

    context "when the Accept-Encoding header is not present" do
      it "should not negotiate  an encoding" do
        headers['Accept-Encoding'].should be_nil
        subject.should_not_receive(:f7)
        subject.run
        response.code.should_not == 406
        # It should not be compressed
        response.body.should == 'test resource'
      end
    end
  end

  describe "#g7 (Resource exists?)" do
    let(:resource) { resource_with { attr_accessor :exist; def resource_exists?; @exist; end } }

    it "should not enter conditional requests if missing (and eventually reply with 404)" do
      resource.exist = false
      subject.should_not_receive(:g8)
      subject.run
      response.code.should == 404
    end

    it "should not reply with 404 if it does exist" do
      resource.exist = true
      subject.should_not_receive(:h7)
      subject.run
      response.code.should_not == 404
    end
  end

  # Conditional requests/preconditions
  describe "#g8, #g9, #g10 (ETag match)" do
    let(:resource) { resource_with { def generate_etag; "etag"; end } }
    it "should skip ETag matching when If-Match is missing" do
      headers['If-Match'].should be_nil
      subject.should_not_receive(:g9)
      subject.should_not_receive(:g11)
      subject.run
      response.code.should_not == 412
    end
    it "should not reply with 304 when If-Match is *" do
      headers['If-Match'] = "*"
      subject.run
      response.code.should_not == 412
    end
    it "should reply with 412 if the ETag is not in If-Match" do
      headers['If-Match'] = '"notetag"'
      subject.run
      response.code.should == 412
    end
    it "should not reply with 412 if the ETag is in If-Match" do
      headers['If-Match'] = '"etag"'
      subject.run
      response.code.should_not == 412
    end
  end

  describe "#h10, #h11, #h12 (If-Unmodified-Since match [IUMS])" do
    let(:resource) { resource_with { attr_accessor :now; def last_modified; @now; end } }
    before { @now = resource.now = Time.now }

    it "should skip LM matching if IUMS is missing" do
      headers['If-Unmodified-Since'].should be_nil
      subject.should_not_receive(:h11)
      subject.should_not_receive(:h12)
      subject.run
      response.code.should_not == 412
    end

    it "should skip LM matching if IUMS is an invalid date" do
      headers['If-Unmodified-Since'] = "garbage"
      subject.should_not_receive(:h12)
      subject.run
      response.code.should_not == 412
    end

    it "should not reply with 412 if LM is <= IUMS" do
      headers['If-Unmodified-Since'] = (@now + 100).httpdate
      subject.run
      response.code.should_not == 412
    end

    it "should reply with 412 if LM is > IUMS" do
      headers['If-Unmodified-Since'] = (@now - 100).httpdate
      subject.run
      response.code.should == 412
    end
  end

  describe "#i12, #i13, #k13, #j18 (If-None-Match match)" do
    let(:resource) do
      resource_with do
        def generate_etag; "etag"; end;
        def process_post; true; end
        def allowed_methods; %w{GET HEAD POST}; end
      end
    end

    it "should skip ETag matching if If-None-Match is missing" do
      headers['If-None-Match'].should be_nil
      %w{i13 k13 j18}.each do |m|
        subject.should_not_receive(m.to_sym)
      end
      subject.run
      [304, 412].should_not include(response.code)
    end

    it "should not reply with 412 or 304 if the ETag is not in If-None-Match" do
      headers['If-None-Match'] = '"notetag"'
      subject.run
      [304, 412].should_not include(response.code)
    end

    context "when the method is GET or HEAD" do
      let(:method){ %w{GET HEAD}[rand(1)] }
      it "should reply with 304 when If-None-Match is *" do
        headers['If-None-Match'] = '*'
      end
      it "should reply with 304 when the ETag is in If-None-Match" do
        headers['If-None-Match'] = '"etag", "foobar"'
      end
      after { subject.run; response.code.should == 304 }
    end

    context "when the method is not GET or HEAD" do
      let(:method){ "POST" }
      let(:body) { "This is the body." }
      let(:headers){ Webmachine::Headers["Content-Type" => "text/plain"] }

      it "should reply with 412 when If-None-Match is *" do
        headers['If-None-Match'] = '*'
      end

      it "should reply with 412 when the ETag is in If-None-Match" do
        headers['If-None-Match'] = '"etag"'
      end
      after { subject.run; response.code.should == 412 }
    end
  end

  describe "#l13, #l14, #l15, #l17 (If-Modified-Since match)" do
    let(:resource) { resource_with { attr_accessor :now; def last_modified; @now; end } }
    before { @now = resource.now = Time.now }
    it "should skip LM matching if IMS is missing" do
      headers['If-Modified-Since'].should be_nil
      %w{l14 l15 l17}.each do |m|
        subject.should_not_receive(m.to_sym)
      end
      subject.run
      response.code.should_not == 304
    end

    it "should skip LM matching if IMS is an invalid date" do
      headers['If-Modified-Since'] = "garbage"
      %w{l15 l17}.each do |m|
        subject.should_not_receive(m.to_sym)
      end
      subject.run
      response.code.should_not == 304
    end

    it "should skip LM matching if IMS is later than current time" do
      headers['If-Modified-Since'] = (@now + 1000).httpdate
      subject.should_not_receive(:l17)
      subject.run
      response.code.should_not == 304
    end

    it "should reply with 304 if LM is <= IMS" do
      headers['If-Modified-Since'] = (@now - 1).httpdate
      resource.now = @now - 1000
      subject.run
      response.code.should == 304
    end

    it "should not reply with 304 if LM is > IMS" do
      headers['If-Modified-Since'] = (@now - 1000).httpdate
      subject.run
      response.code.should_not == 304
    end
  end

  # Resource missing branch (upper right)
  describe "#h7 (If-Match: * exists?)" do
    let(:resource) { missing_resource }
    it "should reply with 412 when the If-Match header is *" do
      headers['If-Match'] = '"*"'
      subject.run
      response.code.should == 412
    end

    it "should not reply with 412 when the If-Match header is missing or not *" do
      headers['If-Match'] = ['"etag"', nil][rand(1)]
      subject.run
      response.code.should_not == 412
    end
  end

  describe "#i7 (PUT?)" do
    let(:resource) do
      missing_resource_with do
        def allowed_methods; %w{GET HEAD PUT POST}; end
        def process_post; true; end
      end
    end
    let(:body) { %W{GET HEAD DELETE}.include?(method) ? nil : "This is the body." }
    before { headers['Content-Type'] = 'text/plain' }

    context "when the method is PUT" do
      let(:method){ "PUT" }

      it "should not reach state k7" do
        subject.should_not_receive(:k7)
        subject.run
      end

      after { [404, 410, 303].should_not include(response.code) }
    end

    context "when the method is not PUT" do
      let(:method){ %W{GET HEAD POST DELETE}[rand(4)] }

      it "should not reach state i4" do
        subject.should_not_receive(:i4)
        subject.run
      end

      after { response.code.should_not == 409 }
    end
  end

  describe "#i4 (Apply to a different URI?)" do
    let(:resource) do
      missing_resource_with do
        attr_accessor :location
        def moved_permanently?; @location; end
        def allowed_methods; %w[PUT]; end
      end
    end
    let(:method){ "PUT" }
    let(:body){ "This is the body." }
    let(:headers) { Webmachine::Headers["Content-Type" => "text/plain", "Content-Length" => body.size.to_s] }

    it "should reply with 301 when the resource has moved" do
      resource.location = URI.parse("http://localhost:8098/newuri")
      subject.run
      response.code.should == 301
      response.headers['Location'].should == resource.location.to_s
    end

    it "should not reply with 301 when resource has not moved" do
      resource.location = false
      subject.run
      response.code.should_not == 301
    end
  end

  describe "#k7 (Previously existed?)"
  describe "#k5 (Moved permanently?)"
  describe "#l7 (POST?)"
  describe "#l5 (Moved temporarily?)"
  describe "#m5 (POST?)"
  describe "#m7 (POST to missing resource?)"
  describe "#n5 (POST to missing resource?)"
  describe "#p3 (Conflict?)"

  # Bottom right
  describe "#n11 (Redirect?)"
  describe "#p11 (New resource?)"
  describe "#o14 (Conflict?)"
  describe "#m16 (DELETE?)"
  describe "#n16 (POST?)"
  describe "#o16 (PUT?)"
  describe "#o18 (Multiple representations?)"
  describe "#m20 (Delete enacted?)"
  describe "#o20 (Response has entity?)"
end
