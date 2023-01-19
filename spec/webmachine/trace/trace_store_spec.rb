require 'spec_helper'
require 'fileutils'

shared_examples_for 'trace storage' do
  it { is_expected.to respond_to(:[]=) }
  it { is_expected.to respond_to(:keys) }
  it { is_expected.to respond_to(:fetch) }

  it 'stores a trace' do
    subject['foo'] = [:bar]
    expect(subject.fetch('foo')).to eq([:bar])
  end

  it 'lists a stored trace in the keys' do
    subject['foo'] = [:bar]
    expect(subject.keys).to eq(['foo'])
  end
end

describe Webmachine::Trace::PStoreTraceStore do
  subject { described_class.new('./wmtrace') }
  after { FileUtils.rm_rf('./wmtrace') }
  it_behaves_like 'trace storage'
end

describe 'Webmachine::Trace :memory Trace Store (Hash)' do
  subject { {} }
  it_behaves_like 'trace storage'
end
