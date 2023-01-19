require 'spec_helper'

describe Webmachine::Trace do
  subject { described_class }

  context 'determining whether the resource should be traced' do
    include_context 'default resource'
    it 'does not trace by default' do
      expect(subject.trace?(resource)).to be(false)
    end

    it 'traces when the resource enables tracing' do
      expect(resource).to receive(:trace?).and_return(true)
      expect(subject.trace?(resource)).to be(true)
    end
  end
end
