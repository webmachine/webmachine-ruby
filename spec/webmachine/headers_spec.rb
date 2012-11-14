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

  describe ".[]" do
    context "Webmachine::Headers['Content-Type', 'application/json']" do
      it "creates a hash with lowercase keys" do
        headers = described_class[
          'Content-Type', 'application/json',
          'Accept', 'application/json'
        ]

        headers.to_hash.should == {
          'content-type' => 'application/json',
          'accept' => 'application/json'
        }
      end
    end

    context "Webmachine::Headers[[['Content-Type', 'application/json']]]" do
      it "creates a hash with lowercase keys" do
        headers = described_class[
          [
            ['Content-Type', 'application/json'],
            ['Accept', 'application/json']
          ]
        ]

        headers.to_hash.should == {
          'content-type' => 'application/json',
          'accept' => 'application/json'
        }
      end
    end

    context "Webmachine::Headers['Content-Type' => 'application/json']" do
      it "creates a hash with lowercase keys" do
        headers = described_class[
          'Content-Type' => 'application/json',
          'Accept' => 'application/json'
        ]

        headers.to_hash.should == {
          'content-type' => 'application/json',
          'accept' => 'application/json'
        }
      end
    end
  end

  describe "#fetch" do
    subject { described_class['Content-Type' => 'application/json'] }

    it "returns the value for the given key" do
      subject.fetch('conTent-tYpe').should == 'application/json'
    end

    context "acessing a missing key" do
      it "raises an IndexError" do
        expect { subject.fetch('accept') }.to raise_error(IndexError)
      end

      context "and a default value given" do
        it "returns the default value if the key does not exist" do
          subject.fetch('accept', 'text/html').should == 'text/html'
        end
      end

      context "and a block given" do
        it "passes the value to the block and returns the block's result" do
          subject.fetch('access') {|k| "#{k} not found"}.should == 'access not found'
        end
      end
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
