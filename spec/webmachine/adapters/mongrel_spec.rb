require "spec_helper"
require "webmachine/spec/adapter_lint"

begin
  describe Webmachine::Adapters::Mongrel do
    it_should_behave_like :adapter_lint do
      it "should set Server header" do
        response = client.request(Net::HTTP::Get.new("/test"))
        expect(response["Server"]).to match(/Webmachine/)
        expect(response["Server"]).to match(/Mongrel/)
      end
    end
  end
rescue LoadError
  warn "Platform is #{RUBY_PLATFORM}: skipping mongrel adapter spec."
end
