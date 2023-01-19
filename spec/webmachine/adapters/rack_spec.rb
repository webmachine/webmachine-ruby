require 'webmachine/adapter'
require 'webmachine/adapters/rack'
require 'spec_helper'
require 'webmachine/spec/adapter_lint'
require 'rack/test'

describe Webmachine::Adapters::Rack do
  it_should_behave_like :adapter_lint do
    it 'should set Server header' do
      response = client.request(Net::HTTP::Get.new('/test'))
      expect(response['Server']).to match(/Webmachine/)
      expect(response['Server']).to match(/Rack/)
    end
  end
end

describe Webmachine::Adapters::Rack::RackResponse do
  context 'on Rack < 1.5 release' do
    before { allow(Rack).to receive_messages(release: '1.4') }

    it 'should add Content-Type header on not acceptable response' do
      rack_response = described_class.new(double(:body), 406, {})
      _rack_status, rack_headers, _rack_body = rack_response.finish
      expect(rack_headers).to have_key('Content-Type')
    end
  end

  context 'on Rack >= 1.5 release' do
    before { allow(Rack).to receive_messages(release: '1.5') }

    it 'should not add Content-Type header on not acceptable response' do
      rack_response = described_class.new(double(:body), 406, {})
      _rack_status, rack_headers, _rack_body = rack_response.finish
      expect(rack_headers).not_to have_key('Content-Type')
    end
  end
end

describe Webmachine::Adapters::Rack do
  let(:app) do
    Webmachine::Application.new do |app|
      app.add_route(['test'], Test::Resource)
      app.configure do |config|
        config.adapter = :Rack
      end
    end.adapter
  end

  context 'using Rack::Test' do
    include Rack::Test::Methods

    it 'provides the full request URI' do
      rack_response = get 'test', nil, {'HTTP_ACCEPT' => 'test/response.request_uri'}
      expect(rack_response.body).to eq 'http://example.org/test'
    end

    it 'provides the rack env on the request' do
      rack_response = get 'test', nil, {'HTTP_ACCEPT' => 'test/response.rack_env'}
      expect(JSON.parse(rack_response.body).keys).to include 'rack.input'
    end
  end
end
