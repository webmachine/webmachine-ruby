require "spec_helper"

describe Webmachine::Adapters::WEBrick do
  let(:configuration) { Webmachine::Configuration.default }
  let(:dispatcher) { Webmachine::Dispatcher.new }
  let(:adapter) do
    described_class.new(configuration, dispatcher)
  end

  describe "#initialize" do
    it "stores the provided configuration" do
      adapter.configuration.should eql configuration
    end

    it "stores the provided dispatcher" do
      adapter.dispatcher.should eql dispatcher
    end
  end

  describe ".run" do
    it "creates a new adapter and runs it" do
      adapter = mock(described_class)

      described_class.should_receive(:new).
        with(configuration, dispatcher).
        and_return(adapter)

      adapter.should_receive(:run)

      described_class.run(configuration, dispatcher)
    end
  end
end
