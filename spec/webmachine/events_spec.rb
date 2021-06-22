require 'spec_helper'

describe Webmachine::Events do
  describe ".backend" do
    it "defaults to AS::Notifications" do
      expect(described_class.backend).to be(AS::Notifications)
    end
  end

  describe ".publish" do
    it "calls the backend" do
      expect(described_class.backend).to receive(:publish).with('test.event', 1, 'two')
      described_class.publish('test.event', 1, 'two')
    end
  end

  describe ".instrument" do
    it "calls the backend" do
      expect(described_class.backend).to receive(:instrument).with(
        'test.event', {}
      ).and_yield

      described_class.instrument('test.event') { }
    end
  end

  describe ".subscribe" do
    it "calls the backend" do
      expect(described_class.backend).to receive(:subscribe).with(
        'test.event'
      ).and_yield

      described_class.subscribe('test.event') { }
    end
  end

  describe ".subscribed" do
    it "calls the backend" do
      callback = Proc.new { }

      expect(described_class.backend).to receive(:subscribed).with(
        callback, 'test.event'
      ).and_yield

      described_class.subscribed(callback, 'test.event') { }
    end
  end

  describe ".unsubscribe" do
    it "calls the backend" do
      subscriber = described_class.subscribe('test.event', Proc.new { })

      expect(described_class.backend).to receive(:unsubscribe).with(subscriber)

      described_class.unsubscribe(subscriber)
    end
  end
end
