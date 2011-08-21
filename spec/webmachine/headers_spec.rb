require 'spec_helper'

describe Webmachine::Headers do
  it "should set and access values insensitive to case" do
    subject['Content-TYPE'] = "text/plain"
    subject['CONTENT-TYPE'].should == 'text/plain'
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
