require "webmachine/spec/test_resource"
require "net/http"

shared_examples_for :adapter_lint do
  attr_accessor :client

  let(:address) { "127.0.0.1" }
  let(:port) { s = TCPServer.new(address, 0); p = s.addr[1]; s.close; p }

  let(:application) do
    application = Webmachine::Application.new
    application.dispatcher.add_route ["test"], Test::Resource

    application.configure do |c|
      c.ip = address
      c.port = port
    end

    application
  end

  let(:client) do
    client = Net::HTTP.new(application.configuration.ip, port)
    # Wait until the server is responsive
    timeout(5) do
      begin
        client.start
      rescue Errno::ECONNREFUSED
        sleep(0.01)
        retry
      end
    end
    client
  end

  before do
    @adapter = described_class.new(application)

    Thread.abort_on_exception = true
    @server_thread = Thread.new { @adapter.run }
    sleep(0.01)
  end

  after do
    client.finish
    @server_thread.kill
  end

  it "provides the request URI" do
    request = Net::HTTP::Get.new("/test")
    request["Accept"] = "test/response.request_uri"
    response = client.request(request)
    expect(response.body).to eq("http://#{address}:#{port}/test")
  end

  context do
    let(:address) { "::1" }

    it "provides the IPv6 request URI" do
      if RUBY_VERSION =~ /^2\.(0|1)\./
        skip "Net::HTTP regression in Ruby 2.(0|1)"
      end

      request = Net::HTTP::Get.new("/test")
      request["Accept"] = "test/response.request_uri"
      response = client.request(request)
      expect(response.body).to eq("http://[#{address}]:#{port}/test")
    end
  end

  it "provides a string-like request body" do
    request = Net::HTTP::Put.new("/test")
    request.body = "Hello, World!"
    request["Content-Type"] = "test/request.stringbody"
    response = client.request(request)
    expect(response["Content-Length"]).to eq("21")
    expect(response.body).to eq("String: Hello, World!")
  end

  it "provides an enumerable request body" do
    request = Net::HTTP::Put.new("/test")
    request.body = "Hello, World!"
    request["Content-Type"] = "test/request.enumbody"
    response = client.request(request)
    expect(response["Content-Length"]).to eq("19")
    expect(response.body).to eq("Enum: Hello, World!")
  end

  it "handles missing pages" do
    request = Net::HTTP::Get.new("/missing")
    response = client.request(request)
    expect(response.code).to eq("404")
    expect(response["Content-Type"]).to eq("text/html")
  end

  it "handles empty response bodies" do
    request = Net::HTTP::Post.new("/test")
    request.body = ""
    response = client.request(request)
    expect(response.code).to eq("204")
    expect(["0", nil]).to include(response["Content-Length"])
    expect(response.body).to be_nil
  end

  it "handles string response bodies" do
    request = Net::HTTP::Get.new("/test")
    request["Accept"] = "test/response.stringbody"
    response = client.request(request)
    expect(response["Content-Length"]).to eq("20")
    expect(response.body).to eq("String response body")
  end

  it "handles enumerable response bodies" do
    request = Net::HTTP::Get.new("/test")
    request["Accept"] = "test/response.enumbody"
    response = client.request(request)
    expect(response["Transfer-Encoding"]).to eq("chunked")
    expect(response.body).to eq("Enumerable response body")
  end

  it "handles proc response bodies" do
    request = Net::HTTP::Get.new("/test")
    request["Accept"] = "test/response.procbody"
    response = client.request(request)
    expect(response["Transfer-Encoding"]).to eq("chunked")
    expect(response.body).to eq("Proc response body")
  end

  it "handles fiber response bodies" do
    request = Net::HTTP::Get.new("/test")
    request["Accept"] = "test/response.fiberbody"
    response = client.request(request)
    expect(response["Transfer-Encoding"]).to eq("chunked")
    expect(response.body).to eq("Fiber response body")
  end

  it "handles io response bodies" do
    request = Net::HTTP::Get.new("/test")
    request["Accept"] = "test/response.iobody"
    response = client.request(request)
    expect(response["Content-Length"]).to eq("17")
    expect(response.body).to eq("IO response body\n")
  end

  it "handles request cookies" do
    request = Net::HTTP::Get.new("/test")
    request["Accept"] = "test/response.cookies"
    request["Cookie"] = "echo=echocookie"
    response = client.request(request)
    expect(response.body).to eq("echocookie")
  end

  it "handles response cookies" do
    request = Net::HTTP::Get.new("/test")
    request["Accept"] = "test/response.cookies"
    response = client.request(request)
    expect(response["Set-Cookie"]).to eq("cookie=monster, rodeo=clown")
  end
end
