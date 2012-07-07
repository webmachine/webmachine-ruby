require 'spec_helper'
require 'fileutils'

shared_examples_for "trace storage" do
  it { should respond_to(:[]=) }
  it { should respond_to(:keys) }
  it { should respond_to(:fetch) }

  it "stores a trace" do
    subject["foo"] = [:bar]
    subject.fetch("foo").should == [:bar]
  end

  it "lists a stored trace in the keys" do
    subject["foo"] = [:bar]
    subject.keys.should == ["foo"]
  end
end

describe Webmachine::Trace::PStoreTraceStore do
  subject { described_class.new("./wmtrace") }
  after { FileUtils.rm_rf("./wmtrace") }
  it_behaves_like "trace storage"
end

describe "Webmachine::Trace :memory Trace Store (Hash)" do
  subject { Hash.new }
  it_behaves_like "trace storage"
end
