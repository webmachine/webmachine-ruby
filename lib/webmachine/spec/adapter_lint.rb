require 'webmachine/spec/test_resource'
require 'net/http'

ADDRESS = '127.0.0.1'

shared_examples_for :adapter_lint do
  attr_reader :client

  class TestApplicationNotResponsive < Timeout::Error; end

  def find_free_port
    temp_server = TCPServer.new(ADDRESS, 0)
    port = temp_server.addr[1]
    temp_server.close # only frees Ruby resource, socket is in TIME_WAIT at OS level
    # so we can't have our adapter use it too quickly

    sleep(0.1)        # 'Wait' for temp_server to *really* close, not just TIME_WAIT
    port
  end

  def create_test_application(port)
    Webmachine::Application.new.tap do |application|
      application.dispatcher.add_route ['test'], Test::Resource

      application.configure do |c|
        c.ip = ADDRESS
        c.port = port
      end
    end
  end

  def run_application(adapter_class, application)
    adapter = adapter_class.new(application)
    Thread.abort_on_exception = true
    Thread.new { adapter.run }
  end

  def wait_until_server_responds_to(client)
    Timeout.timeout(5, TestApplicationNotResponsive) do
      client.start
    rescue Errno::ECONNREFUSED
      sleep(0.01)
      retry
    end
  end

  before(:all) do
    @port = find_free_port
    application = create_test_application(@port)

    adapter_class = described_class
    @server_thread = run_application(adapter_class, application)

    @client = Net::HTTP.new(application.configuration.ip, @port)
    wait_until_server_responds_to(client)
  end

  after(:all) do
    @client.finish
    @server_thread.kill
  end

  it 'provides the request URI' do
    request = Net::HTTP::Get.new('/test')
    request['Accept'] = 'test/response.request_uri'
    response = client.request(request)
    expect(response.body).to eq("http://#{ADDRESS}:#{@port}/test")
  end

  # context do
  #   let(:address) { "::1" }

  #   it "provides the IPv6 request URI" do
  #     request = Net::HTTP::Get.new("/test")
  #     request["Accept"] = "test/response.request_uri"
  #     response = client.request(request)
  #     expect(response.body).to eq("http://[#{address}]:#{port}/test")
  #   end
  # end

  it 'provides a string-like request body' do
    request = Net::HTTP::Put.new('/test')
    request.body = 'Hello, World!'
    request['Content-Type'] = 'test/request.stringbody'
    response = client.request(request)
    expect(response['Content-Length']).to eq('21')
    expect(response.body).to eq('String: Hello, World!')
  end

  it 'provides an enumerable request body' do
    request = Net::HTTP::Put.new('/test')
    request.body = 'Hello, World!'
    request['Content-Type'] = 'test/request.enumbody'
    response = client.request(request)
    expect(response['Content-Length']).to eq('19')
    expect(response.body).to eq('Enum: Hello, World!')
  end

  it 'handles missing pages' do
    request = Net::HTTP::Get.new('/missing')
    response = client.request(request)
    expect(response.code).to eq('404')
    expect(response['Content-Type']).to eq('text/html')
  end

  it 'handles empty response bodies' do
    request = Net::HTTP::Post.new('/test')
    request.body = ''
    response = client.request(request)
    expect(response.code).to eq('204')
    expect(['0', nil]).to include(response['Content-Length'])
    expect(response.body).to be_nil
  end

  it 'handles string response bodies' do
    request = Net::HTTP::Get.new('/test')
    request['Accept'] = 'test/response.stringbody'
    response = client.request(request)
    expect(response['Content-Length']).to eq('20')
    expect(response.body).to eq('String response body')
  end

  it 'handles enumerable response bodies' do
    request = Net::HTTP::Get.new('/test')
    request['Accept'] = 'test/response.enumbody'
    response = client.request(request)
    expect(response['Transfer-Encoding']).to eq('chunked')
    expect(response.body).to eq('Enumerable response body')
  end

  it 'handles proc response bodies' do
    request = Net::HTTP::Get.new('/test')
    request['Accept'] = 'test/response.procbody'
    response = client.request(request)
    expect(response['Transfer-Encoding']).to eq('chunked')
    expect(response.body).to eq('Proc response body')
  end

  it 'handles fiber response bodies' do
    request = Net::HTTP::Get.new('/test')
    request['Accept'] = 'test/response.fiberbody'
    response = client.request(request)
    expect(response['Transfer-Encoding']).to eq('chunked')
    expect(response.body).to eq('Fiber response body')
  end

  it 'handles io response bodies' do
    request = Net::HTTP::Get.new('/test')
    request['Accept'] = 'test/response.iobody'
    response = client.request(request)
    expect(response['Content-Length']).to eq('17')
    expect(response.body).to eq("IO response body\n")
  end

  it 'handles request cookies' do
    request = Net::HTTP::Get.new('/test')
    request['Accept'] = 'test/response.cookies'
    request['Cookie'] = 'echo=echocookie'
    response = client.request(request)
    expect(response.body).to eq('echocookie')
  end

  it 'handles response cookies' do
    request = Net::HTTP::Get.new('/test')
    request['Accept'] = 'test/response.cookies'
    response = client.request(request)
    expect(response['Set-Cookie']).to eq('cookie=monster, rodeo=clown')
  end
end
