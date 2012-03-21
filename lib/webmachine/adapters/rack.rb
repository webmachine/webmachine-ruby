require 'rack'
require 'webmachine/version'
require 'webmachine/headers'
require 'webmachine/request'
require 'webmachine/response'
require 'webmachine/dispatcher'

module Webmachine
  module Adapters
    # A minimal "shim" adapter to allow Webmachine to interface with Rack. The
    # intention here is to allow Webmachine to run under Rack-compatible
    # web-servers, like unicorn and pow, and is not intended to allow Webmachine
    # to be "plugged in" to an existing Rack app as middleware.
    #
    # To use this adapter, create a config.ru file and populate it like so:
    #
    #     require 'webmachine/adapters/rack'
    #
    #     # put your own Webmachine resources in another file:
    #     require 'my/resources'
    #
    #     run MyApplication.adapter
    #
    # Servers like pow and unicorn will read config.ru by default and it should
    # all "just work".
    #
    # And for development or testing your application can be run with Rack's
    # builtin Server identically to the Mongrel and WEBrick adapters with:
    #
    #     MyApplication.run
    #
    class Rack < Adapter

      # Start the Rack adapter
      def run
        options = {
          :app => self,
          :Port => configuration.port,
          :Host => configuration.ip
        }.merge(configuration.adapter_options)

        ::Rack::Server.start(options)
      end

      # Handles a Rack-based request.
      # @param [Hash] env the Rack environment
      def call(env)
        headers = Webmachine::Headers.from_cgi(env)

        rack_req = ::Rack::Request.new env
        request = Webmachine::Request.new(rack_req.request_method,
                                          URI.parse(rack_req.url),
                                          headers,
                                          RequestBody.new(rack_req))

        response = Webmachine::Response.new
        @dispatcher.dispatch(request, response)

        response.headers['Server'] = [Webmachine::SERVER_STRING, "Rack/#{::Rack.version}"].join(" ")

        body = response.body.respond_to?(:call) ? response.body.call : response.body
        body = body.is_a?(String) ? [ body ] : body

        headers = Hash[response.headers.collect { |k,v|
          case v
          when Array
            [k,v.join("\n")]
          else
            [k,v]
          end
        }]

        [response.code.to_i, headers, body || []]
      end

      # Wraps the Rack input so it can be treated like a String or
      # Enumerable.
      # @api private
      class RequestBody
        # @param [Rack::Request] request the Rack request
        def initialize(request)
          @request = request
        end

        # Converts the body to a String so you can work with the entire
        # thing.
        # @return [String] the request body as a string
        def to_s
          if @value
            @value.join
          else
            @request.body.rewind
            @request.body.read
          end
        end

        # Iterates over the body in chunks. If the body has previously
        # been read, this method can be called again and get the same
        # sequence of chunks.
        # @yield [chunk]
        # @yieldparam [String] chunk a chunk of the request body
        def each
          if @value
            @value.each {|chunk| yield chunk }
          else
            @value = []
            @request.body.each {|chunk| @value << chunk; yield chunk }
          end
        end
      end # class RequestBody
    end # class Rack

  end # module Adapters
end # module Webmachine
