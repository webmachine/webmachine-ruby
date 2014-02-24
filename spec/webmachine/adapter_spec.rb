require "spec_helper"

describe Webmachine::Adapter do
  let(:application) { Webmachine::Application.new }
  let(:adapter) do
    server = TCPServer.new('0.0.0.0', 0)
    application.configuration.port = server.addr[1]
    server.close

    described_class.new(application)
  end

  describe "#initialize" do
    it "stores the provided application" do
      adapter.application.should eql application
    end
  end

  describe ".run" do
    it "creates a new adapter and runs it" do
      adapter = mock(described_class)

      described_class.should_receive(:new).
        with(application).
        and_return(adapter)

      adapter.should_receive(:run)

      described_class.run(application)
    end
  end

  describe "#run" do
    it "raises a NotImplementedError" do
      lambda { adapter.run }.should raise_exception(NotImplementedError)
    end
  end

end
