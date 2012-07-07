require 'spec_helper'

describe Webmachine::Trace do
  subject { described_class }

  context "determining whether the resource should be traced" do
    include_context "default resource"
    it "does not trace by default" do
      subject.trace?(resource).should be_false
    end

    it "traces when the resource enables tracing" do
      resource.should_receive(:trace?).and_return(true)
      subject.trace?(resource).should be_true
    end
  end
end
