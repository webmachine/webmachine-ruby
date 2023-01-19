require 'webmachine/adapters/rack'

module Webmachine
  module Adapters
    # Provides the same functionality as the parent Webmachine::Adapters::Rack
    # adapter, but allows the Webmachine application to be hosted at an
    # arbitrary path in a parent Rack application (as in Rack `map` or Rails
    # routing `mount`)
    #
    # This functionality is separated out from the parent class to preserve
    # backward compatibility in the behaviour of the parent Rack adpater.
    #
    # To use the adapter in a parent Rack application, map the Webmachine
    # application as follows in a rackup file or Rack::Builder:
    #
    #   map '/foo' do
    #     run SomeotherRackApp
    #
    #     map '/bar' do
    #       run MyWebmachineApp.adapter
    #     end
    #   end
    class RackMapped < Rack
      protected

      def routing_tokens(rack_req)
        routing_match = rack_req.path_info.match(Webmachine::Request::ROUTING_PATH_MATCH)
        routing_path = routing_match ? routing_match[1] : ''
        routing_path.split(SLASH)
      end

      def base_uri(rack_req)
        # rack SCRIPT_NAME env var doesn't end with "/". This causes weird
        # behavour when URI.join concatenates URI components in
        # Webmachine::Decision::Flow#n11
        script_name = rack_req.script_name + SLASH
        URI.join(rack_req.base_url, script_name)
      end
    end # class RackMapped
  end # module Adapters
end # module Webmachine
