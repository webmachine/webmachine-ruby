require "spec_helper"
require "webmachine/spec/adapter_lint"

describe Webmachine::Adapters::WEBrick do
  it_should_behave_like :adapter_lint do
    it "should set Server header" do
      response = client.request(Net::HTTP::Get.new("/test"))
      expect(response["Server"]).to match(/Webmachine/)
      expect(response["Server"]).to match(/WEBrick/)
    end
  end
end
