require 'spec_helper'
RSpec.describe Webmachine::RescueableException do
  before { described_class.default! }

  describe ".unrescueables" do
    specify "returns an array of unrescueable exceptions" do
      expect(described_class.unrescueables).to eq(described_class::UNRESCUEABLE_DEFAULTS)
    end

    specify "returns an array of unrescueable exceptions, with custom exceptions added" do
      described_class.remove(Exception)
      expect(described_class.unrescueables).to eq(described_class::UNRESCUEABLE_DEFAULTS.dup.concat([Exception]))
    end
  end
end
