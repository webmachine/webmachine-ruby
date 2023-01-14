require 'spec_helper'

describe Webmachine::Configuration do
  before { Webmachine.configuration = nil }

  %w[ip port adapter adapter_options].each do |field|
    it { is_expected.to respond_to(field) }
    it { is_expected.to respond_to("#{field}=") }
  end

  it 'should yield configuration to the block' do
    Webmachine.configure do |config|
      expect(config).to be_kind_of(described_class)
    end
  end

  it 'should set the global configuration from the yielded instance' do
    Webmachine.configure do |config|
      @config = config
    end
    expect(@config).to eq Webmachine.configuration
  end

  it 'should return the module from the configure call so you can chain it' do
    expect(Webmachine.configure { |c| }).to eq Webmachine
  end
end
