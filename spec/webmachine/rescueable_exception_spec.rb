require 'spec_helper'
RSpec.describe Webmachine::RescuableException do
  before { described_class.default! }

  describe ".UNRESCUABLEs" do
    specify "returns an array of UNRESCUABLE exceptions" do
      expect(described_class.UNRESCUABLEs).to eq(described_class::UNRESCUABLE_DEFAULTS)
    end

    specify "returns an array of UNRESCUABLE exceptions, with custom exceptions added" do
      described_class.remove(Exception)
      expect(described_class.UNRESCUABLEs).to eq(described_class::UNRESCUABLE_DEFAULTS.dup.concat([Exception]))
    end
  end
end
