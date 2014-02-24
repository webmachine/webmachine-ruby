require 'spec_helper'

describe Webmachine::Request do
  subject { request }

  let(:uri)         { URI.parse("http://localhost:#{$testmachine_port}/some/resource") }
  let(:http_method) { "GET" }
  let(:headers)     { Webmachine::Headers.new }
  let(:body)        { "" }
  let(:request)     { Webmachine::Request.new(http_method, uri, headers, body) }

  it "should provide access to the headers via brackets" do
    subject.headers['Accept'] = "*/*"
    subject["accept"].should == "*/*"
  end

  it "should provide access to the cookies" do
    subject.headers['Cookie'] = 'name=value;name2=value2';
    subject.cookies.should == { 'name' => 'value', 'name2' => 'value2' }
  end

  it "should handle cookies with extra whitespace" do
    subject.headers['Cookie'] = 'name = value; name2 = value2';
    subject.cookies.should == { 'name' => 'value', 'name2' => 'value2' }
  end

  it "should provide access to the headers via underscored methods" do
    subject.headers["Accept-Encoding"] = "identity"
    subject.accept_encoding.should == "identity"
    subject.content_md5.should be_nil
  end

  it "should calculate a base URI" do
    subject.base_uri.should == URI.parse("http://localhost:#{$testmachine_port}/")
  end

  it "should provide a hash of query parameters" do
    subject.uri.query = "foo=bar&baz=bam"
    subject.query.should == {"foo" => "bar", "baz" => "bam"}
  end

  it "should handle = being encoded as a query value." do
    subject.uri.query = "foo=bar%3D%3D"
    subject.query.should == { "foo" => "bar=="}
  end

  it "should treat '+' characters in query parameters as spaces" do
    subject.uri.query = "a%20b=foo+bar&c+d=baz%20quux"
    subject.query.should == {"a b" => "foo bar", "c d" => "baz quux"}
  end

  it "should handle a query parameter value of nil" do
    subject.uri.query = nil
    subject.query.should == {}
  end

  describe '#has_body?' do
    let(:wreq) do
      Class.new {
        def initialize(body); @body = body; end
        def body; block_given? ? yield(@body) : @body; end
      }
    end

    subject { request.has_body? }

    context "when body is nil" do
      let(:body) { nil }

      it { should be_false }
    end

    context "when body is an empty string" do
      let(:body) { '' }

      it { should be_false }
    end

    context "when body is not empty" do
      let(:body) { 'foo' }

      it { should be_true }
    end

    context "when body is an empty LazyRequestBody" do
      let(:body) { Webmachine::Adapters::LazyRequestBody.new(wreq.new('')) }

      it { should be_false }
    end

    context "when body is a LazyRequestBody" do
      let(:body) { Webmachine::Adapters::LazyRequestBody.new(wreq.new('foo')) }

      it { should be_true }
    end
  end

  describe '#https?' do
    subject { request.https? }

    context "when the request was issued via HTTPS" do
      let(:uri) { URI.parse("https://localhost.com:#{$testmachine_port}/some/resource") }

      it { should be_true }
    end

    context "when the request was not issued via HTTPS" do
      let(:uri) { URI.parse("http://localhost.com:#{$testmachine_port}/some/resource") }

      it { should be_false }
    end
  end

  describe '#get?' do
    subject { request.get? }

    context "when the request method is GET" do
      let(:http_method) { "GET" }

      it { should be_true }
    end

    context "when the request method is not GET" do
      let(:http_method) { "POST" }

      it { should be_false }
    end
  end

  describe '#head?' do
    subject { request.head? }

    context "when the request method is HEAD" do
      let(:http_method) { "HEAD" }

      it { should be_true }
    end

    context "when the request method is not HEAD" do
      let(:http_method) { "GET" }

      it { should be_false }
    end
  end

  describe '#post?' do
    subject { request.post? }

    context "when the request method is POST" do
      let(:http_method) { "POST" }

      it { should be_true }
    end

    context "when the request method is not POST" do
      let(:http_method) { "GET" }

      it { should be_false }
    end
  end

  describe '#put?' do
    subject { request.put? }

    context "when the request method is PUT" do
      let(:http_method) { "PUT" }

      it { should be_true }
    end

    context "when the request method is not PUT" do
      let(:http_method) { "GET" }

      it { should be_false }
    end
  end

  describe '#delete?' do
    subject { request.delete? }

    context "when the request method is DELETE" do
      let(:http_method) { "DELETE" }

      it { should be_true }
    end

    context "when the request method is not DELETE" do
      let(:http_method) { "GET" }

      it { should be_false }
    end
  end

  describe '#trace?' do
    subject { request.trace? }

    context "when the request method is TRACE" do
      let(:http_method) { "TRACE" }

      it { should be_true }
    end

    context "when the request method is not TRACE" do
      let(:http_method) { "GET" }

      it { should be_false }
    end
  end

  describe '#connect?' do
    subject { request.connect? }

    context "when the request method is CONNECT" do
      let(:http_method) { "CONNECT" }

      it { should be_true }
    end

    context "when the request method is not CONNECT" do
      let(:http_method) { "GET" }

      it { should be_false }
    end
  end

  describe '#options?' do
    subject { request.options? }

    context "when the request method is OPTIONS" do
      let(:http_method) { "OPTIONS" }

      it { should be_true }
    end

    context "when the request method is not OPTIONS" do
      let(:http_method) { "GET" }

      it { should be_false }
    end
  end

end
