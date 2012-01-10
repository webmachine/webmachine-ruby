require "spec_helper"

describe Webmachine::Adapters::Mongrel do
  let(:configuration) { Webmachine::Configuration.default }
  let(:dispatcher) { Webmachine::Dispatcher.new }

  let(:adapter) do
    described_class.new(configuration, dispatcher)
  end

  it "inherits from Webmachine::Adapter" do
    adapter.should be_a_kind_of(Webmachine::Adapter)
  end

  it "implements #run" do
    described_class.instance_methods(false).should include :run
  end
end
