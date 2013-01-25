require "support/test_resource"
require "net/http"

shared_examples_for :adapter_lint do
  let(:configuration) { Webmachine::Configuration.default }
  let(:dispatcher) { Webmachine::Dispatcher.new }

  let(:adapter) do
    described_class.new(configuration, dispatcher)
  end

  let(:client) { Net::HTTP.new(configuration.ip, configuration.port) }

  before do
    dispatcher.add_route ["test"], Test::Resource
  end

  before(:all) do
    Thread.new { adapter.run }

    # Wait until the server is responsive
    timeout(5) do
      request = Net::HTTP::Get.new("/test")
      begin
        client.request(request)
      rescue Errno::ECONNREFUSED
        Thread.pass
        retry
      end
    end
  end

  after(:all) do
    adapter.shutdown
  end

  it "provides a string-like request body" do
    request = Net::HTTP::Put.new("/test")
    request.body = "Hello, World!"
    request["Content-Type"] = "test/request.stringbody"
    response = client.request(request)
    response["Content-Length"].should eq("21")
    response.body.should eq("String: Hello, World!")
  end

  it "provides an enumerable request body" do
    request = Net::HTTP::Put.new("/test")
    request.body = "Hello, World!"
    request["Content-Type"] = "test/request.enumbody"
    response = client.request(request)
    response["Content-Length"].should eq("19")
    response.body.should eq("Enum: Hello, World!")
  end

  it "handles missing pages" do
    request = Net::HTTP::Get.new("/missing")
    response = client.request(request)
    response.code.should eq("404")
    response["Content-Type"].should eq("text/html")
  end

  it "handles empty response bodies" do
    request = Net::HTTP::Post.new("/test")
    response = client.request(request)
    response.code.should eq("204")
    # FIXME: Mongrel/WEBrick fail this test. Is there a bug?
    #response["Content-Type"].should be_nil
    response["Content-Length"].should be_nil
    response.body.should be_nil
  end

  it "handles string response bodies" do
    request = Net::HTTP::Get.new("/test")
    request["Accept"] = "test/response.stringbody"
    response = client.request(request)
    response["Content-Length"].should eq("20")
    response.body.should eq("String response body")
  end

  it "handles enumerable response bodies" do
    request = Net::HTTP::Get.new("/test")
    request["Accept"] = "test/response.enumbody"
    response = client.request(request)
    response["Transfer-Encoding"].should eq("chunked")
    response.body.should eq("Enumerable response body")
  end

  it "handles proc response bodies" do
    request = Net::HTTP::Get.new("/test")
    request["Accept"] = "test/response.procbody"
    response = client.request(request)
    response["Transfer-Encoding"].should eq("chunked")
    response.body.should eq("Proc response body")
  end

  it "handles fiber response bodies" do
    request = Net::HTTP::Get.new("/test")
    request["Accept"] = "test/response.fiberbody"
    response = client.request(request)
    response["Transfer-Encoding"].should eq("chunked")
    response.body.should eq("Fiber response body")
  end

  it "handles request cookies" do
    request = Net::HTTP::Get.new("/test")
    request["Accept"] = "test/response.cookies"
    request["Cookie"] = "echo=echocookie"
    response = client.request(request)
    response.body.should eq("echocookie")
  end

  it "handles response cookies" do
    request = Net::HTTP::Get.new("/test")
    request["Accept"] = "test/response.cookies"
    response = client.request(request)
    response["Set-Cookie"].should eq("cookie=monster, rodeo=clown")
  end
end
