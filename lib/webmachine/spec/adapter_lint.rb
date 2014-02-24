require "webmachine/spec/test_resource"
require "net/http"

shared_examples_for :adapter_lint do
  attr_accessor :client

  before(:all) do
    application = Webmachine::Application.new
    server = TCPServer.new('0.0.0.0', 0)
    application.configuration.port = server.addr[1]
    server.close
    application.dispatcher.add_route ["test"], Test::Resource

    @adapter = described_class.new(application)
    @client = Net::HTTP.new(application.configuration.ip, application.configuration.port)

    Thread.abort_on_exception = true
    @server_thread = Thread.new { @adapter.run }

    # Wait until the server is responsive
    timeout(5) do
      begin
        client.start
      rescue Errno::ECONNREFUSED
        sleep(0.1)
        retry
      end
    end
  end

  after(:all) do
    @adapter.shutdown
    @client.finish
    @server_thread.join
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
    request.body = ""
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

  it "handles io response bodies" do
    request = Net::HTTP::Get.new("/test")
    request["Accept"] = "test/response.iobody"
    response = client.request(request)
    response["Content-Length"].should eq("16")
    response.body.should eq("IO response body")
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
