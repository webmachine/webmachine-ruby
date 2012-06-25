require 'spec_helper'

describe Webmachine::Trace::FSM do
  include_context "default resource"

  subject { Webmachine::Decision::FSM.new(resource, request, response) }
  before { Webmachine::Trace.trace_store = :memory }

  context "when tracing is enabled" do
    before { Webmachine::Trace.stub!(:trace?).and_return(true) }

    it "proxies the resource" do
      subject.resource.should be_kind_of(Webmachine::Trace::ResourceProxy)
    end

    it "records a trace" do
      subject.run
      response.trace.should_not be_empty
      Webmachine::Trace.traces.should have(1).item
    end
  end

  context "when tracing is disabled" do
    before { Webmachine::Trace.stub!(:trace?).and_return(false) }

    it "leaves no trace" do
      subject.run
      response.trace.should be_empty
      Webmachine::Trace.traces.should be_empty
    end
  end
end
