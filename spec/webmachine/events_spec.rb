require 'spec_helper'

describe Webmachine::Events do
  describe ".backend" do
    it "defaults to AS::Notifications" do
      described_class.backend.should be(AS::Notifications)
    end
  end

  describe ".publish" do
    it "calls the backend" do
      described_class.backend.should_receive(:publish).with('test.event', 1, 'two')
      described_class.publish('test.event', 1, 'two')
    end
  end

  describe ".instrument" do
    it "calls the backend" do
      described_class.backend.should_receive(:instrument).with(
        'test.event', {}
      ).and_yield

      described_class.instrument('test.event') { }
    end
  end

  describe ".subscribe" do
    it "calls the backend" do
      described_class.backend.should_receive(:subscribe).with(
        'test.event'
      ).and_yield

      described_class.subscribe('test.event') { }
    end
  end

  describe ".subscribed" do
    it "calls the backend" do
      callback = Proc.new { }

      described_class.backend.should_receive(:subscribed).with(
        callback, 'test.event'
      ).and_yield

      described_class.subscribed(callback, 'test.event') { }
    end
  end

  describe ".unsubscribe" do
    it "calls the backend" do
      subscriber = described_class.subscribe('test.event') { }

      described_class.backend.should_receive(:unsubscribe).with(subscriber)

      described_class.unsubscribe(subscriber)
    end
  end
end
