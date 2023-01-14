require 'spec_helper'

describe Webmachine::Adapter do
  let(:application) { Webmachine::Application.new }
  let(:adapter) do
    server = TCPServer.new('0.0.0.0', 0)
    application.configuration.port = server.addr[1]
    server.close

    described_class.new(application)
  end

  describe '#initialize' do
    it 'stores the provided application' do
      expect(adapter.application).to eq(application)
    end
  end

  describe '.run' do
    it 'creates a new adapter and runs it' do
      adapter = double(described_class)

      expect(described_class).to receive(:new).
        with(application).
        and_return(adapter)

      expect(adapter).to receive(:run)

      described_class.run(application)
    end
  end

  describe '#run' do
    it 'raises a NotImplementedError' do
      expect { adapter.run }.to raise_exception(NotImplementedError)
    end
  end

end
