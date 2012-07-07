require 'spec_helper'

describe Webmachine::Headers do
  it "should set and access values insensitive to case" do
    subject['Content-TYPE'] = "text/plain"
    subject['CONTENT-TYPE'].should == 'text/plain'
    subject.delete('CoNtEnT-tYpE').should == 'text/plain'
  end

  describe "#from_cgi" do
    it "should understand the Content-Length header" do
      headers = described_class.from_cgi("CONTENT_LENGTH" => 14)
      headers["content-length"].should == 14
    end
  end

  context "filtering with #grep" do
    subject { described_class["content-type" => "text/plain", "etag" => '"abcdef1234567890"'] }
    it "should filter keys by the given pattern" do
      subject.grep(/content/i).should include("content-type")
    end

    it "should return a Headers instance" do
      subject.grep(/etag/i).should be_instance_of(described_class)
    end
  end
end
