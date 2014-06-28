require 'spec_helper'

describe Webmachine::Trace::FSM do
  include_context "default resource"

  subject { Webmachine::Decision::FSM.new(resource, request, response) }
  before { Webmachine::Trace.trace_store = :memory }

  context "when tracing is enabled" do
    before { allow(Webmachine::Trace).to receive(:trace?).and_return(true) }

    it "proxies the resource" do
      expect(subject.resource).to be_kind_of(Webmachine::Trace::ResourceProxy)
    end

    it "records a trace" do
      subject.run
      expect(response.trace).to_not be_empty
      expect(Webmachine::Trace.traces.size).to eq(1)
    end

    it "commits the trace to separate storage when the request has finished processing" do
      expect(Webmachine::Trace).to receive(:record).with(subject.resource.object_id.to_s, response.trace).and_return(true)
      subject.run
    end
  end

  context "when tracing is disabled" do
    before { allow(Webmachine::Trace).to receive(:trace?).and_return(false) }

    it "leaves no trace" do
      subject.run
      expect(response.trace).to be_empty
      expect(Webmachine::Trace.traces).to be_empty
    end
  end
end
