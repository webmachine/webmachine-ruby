require 'spec_helper'

describe Webmachine::Request do
  subject { Webmachine::Request.new("GET", URI.parse("http://localhost:8080/some/resource"), Webmachine::Headers.new, "") }
  it "should provide access to the headers via brackets" do
    subject.headers['Accept'] = "*/*"
    subject["accept"].should == "*/*"
  end

  it "should provide access to the headers via underscored methods" do
    subject.headers["Accept-Encoding"] = "identity"
    subject.accept_encoding.should == "identity"
    subject.content_md5.should be_nil
  end

  it "should calculate a base URI" do
    subject.base_uri.should == URI.parse("http://localhost:8080/")
  end

  it "should provide a hash of query parameters" do
    subject.uri.query = "foo=bar&baz=bam"
    subject.query.should == {"foo" => "bar", "baz" => "bam"}
  end

  it "should treat '+' characters in query parameters as spaces" do
    subject.uri.query = "a%20b=foo+bar&c+d=baz%20quux"
    subject.query.should == {"a b" => "foo bar", "c d" => "baz quux"}
  end
end
