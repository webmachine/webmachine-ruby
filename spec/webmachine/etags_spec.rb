require 'spec_helper'

describe Webmachine::ETag do
  let(:etag_str){ '"deadbeef12345678"' }
  let(:etag) { described_class.new etag_str }

  subject { etag }

  it { should == etag_str }
  it { should be_kind_of(described_class) }
  its(:to_s) { should == '"deadbeef12345678"' }
  its(:etag) { should == '"deadbeef12345678"' }
  it { should == described_class.new(etag_str.dup) }

  context "when the original etag is unquoted" do
    let(:etag_str) { 'deadbeef12345678' }

    it { should == etag_str }
    its(:to_s) { should == '"deadbeef12345678"' }
    its(:etag) { should == '"deadbeef12345678"' }
    it { should == described_class.new(etag_str.dup) }
  end

  context "when the original etag contains unbalanced quotes" do
    let(:etag_str) { 'deadbeef"12345678' }

    it { should == etag_str }
    its(:to_s) { should == '"deadbeef\\"12345678"' }
    its(:etag) { should == '"deadbeef\\"12345678"' }
    it { should == described_class.new(etag_str.dup) }
  end
end

describe Webmachine::WeakETag do
  let(:strong_etag){ '"deadbeef12345678"' }
  let(:weak_etag) { described_class.new strong_etag }

  subject { weak_etag }

  it { should == strong_etag }
  it { should be_kind_of(described_class) }
  its(:to_s) { should == 'W/"deadbeef12345678"' }
  its(:etag) { should == '"deadbeef12345678"' }
  it { should == described_class.new(strong_etag.dup) }

  context "when the original etag is unquoted" do
    let(:strong_etag) { 'deadbeef12345678' }

    it { should == strong_etag }
    it { should be_kind_of(described_class) }
    its(:to_s) { should == 'W/"deadbeef12345678"' }
    its(:etag) { should == '"deadbeef12345678"' }
    it { should == described_class.new(strong_etag.dup) }
  end

  context "when the original etag contains unbalanced quotes" do
    let(:strong_etag) { 'deadbeef"12345678' }

    it { should == strong_etag }
    it { should be_kind_of(described_class) }
    its(:to_s) { should == 'W/"deadbeef\\"12345678"' }
    its(:etag) { should == '"deadbeef\\"12345678"' }
    it { should == described_class.new(strong_etag.dup) }
  end

  context "when the original etag is already a weak tag" do
    let(:strong_etag) { 'W/"deadbeef12345678"' }

    it { should == strong_etag }
    it { should be_kind_of(described_class) }
    its(:to_s) { should == 'W/"deadbeef12345678"' }
    its(:etag) { should == '"deadbeef12345678"' }
    it { should == described_class.new(strong_etag.dup) }
  end
end
