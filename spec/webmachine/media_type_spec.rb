require 'spec_helper'

describe Webmachine::MediaType do
  let(:raw_type){ "application/xml;charset=UTF-8" }
  subject { described_class.new("application/xml", {"charset" => "UTF-8"}) }

  context "equivalence" do
    it { should == raw_type }
    it { should == described_class.parse(raw_type) }
  end

  context "when it is the wildcard type" do
    subject { described_class.new("*/*") }
    it { should be_matches_all }
  end

  context "parsing a type" do
    it "should return MediaTypes untouched" do
      described_class.parse(subject).should equal(subject)
    end

    it "should parse a String" do
      type = described_class.parse(raw_type)
      type.should be_kind_of(described_class)
      type.type.should == "application/xml"
      type.params.should == {"charset" => "UTF-8"}
    end

    it "should parse a type/params pair" do
      type = described_class.parse(["application/xml", {"charset" => "UTF-8"}])
      type.should be_kind_of(described_class)
      type.type.should == "application/xml"
      type.params.should ==  {"charset" => "UTF-8"}
    end

    it "should parse a type/params pair where the type has some params in the string" do
      type = described_class.parse(["application/xml;version=1",  {"charset" => "UTF-8"}])
      type.should be_kind_of(described_class)
      type.type.should == "application/xml"
      type.params.should ==  {"charset" => "UTF-8", "version" => "1"}
    end

    it "should parse a type/params pair with params and whitespace in the string" do
      type = described_class.parse(["multipart/form-data; boundary=----------------------------2c46a7bec2b9", {"charset" => "UTF-8"}])
      type.should be_kind_of(described_class)
      type.type.should == "multipart/form-data"
      type.params.should ==  {"boundary" => "----------------------------2c46a7bec2b9", "charset" => "UTF-8"}
    end

    it "should raise an error when given an invalid type/params pair" do
      expect {
        described_class.parse([false, "blah"])
      }.to raise_error(ArgumentError)
    end
  end

  describe "matching a requested type" do
    it { should     be_exact_match("application/xml;charset=UTF-8") }
    it { should     be_exact_match("application/*;charset=UTF-8") }
    it { should     be_exact_match("*/*;charset=UTF-8") }
    it { should     be_exact_match("*;charset=UTF-8") }
    it { should_not be_exact_match("text/xml") }
    it { should_not be_exact_match("application/xml") }
    it { should_not be_exact_match("application/xml;version=1") }

    it { should     be_type_matches("application/xml") }
    it { should     be_type_matches("application/*") }
    it { should     be_type_matches("*/*") }
    it { should     be_type_matches("*") }
    it { should_not be_type_matches("text/xml") }
    it { should_not be_type_matches("text/*") }

    it { should     be_params_match({}) }
    it { should     be_params_match({"charset" => "UTF-8"}) }
    it { should_not be_params_match({"charset" => "Windows-1252"}) }
    it { should_not be_params_match({"version" => "3"}) }
  end
end
