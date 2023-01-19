require 'webmachine/adapter'
require 'webmachine/adapters/rack_mapped'
require 'spec_helper'
require 'webmachine/spec/adapter_lint'
require 'rack/test'

describe Webmachine::Adapters::RackMapped do
  it_should_behave_like :adapter_lint do
    it 'should set Server header' do
      response = client.request(Net::HTTP::Get.new('/test'))
      expect(response['Server']).to match(/Webmachine/)
      expect(response['Server']).to match(/Rack/)
    end
  end
end

describe Webmachine::Adapters::RackMapped do
  class CreateResource < Webmachine::Resource
    def allowed_methods
      ['POST']
    end

    def content_types_accepted
      [['application/json', :from_json]]
    end

    def content_types_provided
      [['application/json', :to_json]]
    end

    def post_is_create?
      true
    end

    def create_path
      'created_path_here/123'
    end

    def from_json
      response.body = %( {"foo": "bar"} )
    end
  end

  let(:app) do
    Rack::Builder.new do
      map '/some/route' do
        run(Webmachine::Application.new do |app|
          app.add_route(['test'], Test::Resource)
          app.add_route(['create_test'], CreateResource)
          app.configure do |config|
            config.adapter = :RackMapped
          end
        end.adapter)
      end
    end
  end

  context 'using Rack::Test' do
    include Rack::Test::Methods

    it 'provides the full request URI' do
      rack_response = get 'some/route/test', nil, {'HTTP_ACCEPT' => 'test/response.request_uri'}
      expect(rack_response.body).to eq 'http://example.org/some/route/test'
    end

    it 'provides LOCATION header using custom base_uri when creating from POST request' do
      rack_response = post '/some/route/create_test', %({"foo": "bar"}), {'HTTP_ACCEPT' => 'application/json', 'CONTENT_TYPE' => 'application/json'}
      expect(rack_response.headers['Location']).to eq('http://example.org/some/route/created_path_here/123')
    end
  end
end
