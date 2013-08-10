require 'webmachine/adapter'
require 'webmachine/adapters/rack'
require 'spec_helper'
require 'support/adapter_lint'

describe Webmachine::Adapters::Rack do
  it_should_behave_like :adapter_lint do
    it "should set Server header" do
      response = client.request(Net::HTTP::Get.new("/test"))
      response["Server"].should match(/Webmachine/)
      response["Server"].should match(/Rack/)
    end
  end
end

describe Webmachine::Adapters::Rack::RackResponse do
  context "on Rack < 1.5 release" do
    before { Rack.stub(:release => "1.4") }

    it "should add Content-Type header on not acceptable response" do
      rack_response = described_class.new(double(:body), 406, {})
      rack_status, rack_headers, rack_body = rack_response.finish
      rack_headers.should have_key("Content-Type")
    end
  end

  context "on Rack >= 1.5 release" do
    before { Rack.stub(:release => "1.5") }

    it "should not add Content-Type header on not acceptable response" do
      rack_response = described_class.new(double(:body), 406, {})
      rack_status, rack_headers, rack_body = rack_response.finish
      rack_headers.should_not have_key("Content-Type")
    end
  end
end
