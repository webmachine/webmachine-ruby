require 'webmachine/adapter'
require 'rack'
require 'webmachine/constants'
require 'webmachine/headers'
require 'webmachine/request'
require 'webmachine/response'
require 'webmachine/version'
require 'webmachine/chunked_body'

module Webmachine
  module Adapters
    # A minimal "shim" adapter to allow Webmachine to interface with Rack. The
    # intention here is to allow Webmachine to run under Rack-compatible
    # web-servers, like unicorn and pow.
    #
    # The adapter expects your Webmachine application to be mounted at the root path -
    # it will NOT allow you to nest your Webmachine application at an arbitrary path
    # eg. map "/api" { run MyWebmachineAPI }
    # To use map your Webmachine application at an arbitrary path, use the
    # `Webmachine::Adapters::RackMapped` subclass instead.
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
    # builtin Server identically to the WEBrick adapter with:
    #
    #     MyApplication.run
    #
    class Rack < Adapter
      # Used to override default Rack server options (useful in testing)
      DEFAULT_OPTIONS = {}

      REQUEST_URI = 'REQUEST_URI'.freeze
      VERSION_STRING = "#{Webmachine::SERVER_STRING} Rack/#{::Rack.version}".freeze
      NEWLINE = "\n".freeze

      # Start the Rack adapter
      def run
        options = DEFAULT_OPTIONS.merge({
          app: self,
          Port: application.configuration.port,
          Host: application.configuration.ip
        }).merge(application.configuration.adapter_options)

        @server = ::Rack::Server.new(options)
        @server.start
      end

      # Handles a Rack-based request.
      # @param [Hash] env the Rack environment
      def call(env)
        headers = Webmachine::Headers.from_cgi(env)

        rack_req = ::Rack::Request.new env
        request = build_webmachine_request(rack_req, headers)

        response = Webmachine::Response.new
        application.dispatcher.dispatch(request, response)

        response.headers[SERVER] = VERSION_STRING

        rack_status = response.code
        rack_headers = response.headers.flattened(NEWLINE)
        rack_body = case response.body
        when String # Strings are enumerable in ruby 1.8
          [response.body]
        else
          if (io_body = IO.try_convert(response.body))
            io_body
          elsif response.body.respond_to?(:call)
            Webmachine::ChunkedBody.new(Array(response.body.call))
          elsif response.body.respond_to?(:each)
            # This might be an IOEncoder with a Content-Length, which shouldn't be chunked.
            if response.headers[TRANSFER_ENCODING] == 'chunked'
              Webmachine::ChunkedBody.new(response.body)
            else
              response.body
            end
          else
            [response.body.to_s]
          end
        end

        rack_res = RackResponse.new(rack_body, rack_status, rack_headers)
        rack_res.finish
      end

      protected

      def routing_tokens(rack_req)
        nil # no-op for default, un-mapped rack adapter
      end

      def base_uri(rack_req)
        nil # no-op for default, un-mapped rack adapter
      end

      private

      def build_webmachine_request(rack_req, headers)
        RackRequest.new(rack_req.request_method,
          rack_req.url,
          headers,
          RequestBody.new(rack_req),
          routing_tokens(rack_req),
          base_uri(rack_req),
          rack_req.env)
      end

      class RackRequest < Webmachine::Request
        attr_reader :env

        def initialize(method, uri, headers, body, routing_tokens, base_uri, env)
          super(method, uri, headers, body, routing_tokens, base_uri)
          @env = env
        end
      end

      class RackResponse
        ONE_FIVE = '1.5'.freeze

        def initialize(body, status, headers)
          @body = body
          @status = status
          @headers = headers
        end

        def finish
          @headers[CONTENT_TYPE] ||= TEXT_HTML if rack_release_enforcing_content_type
          @headers.delete(CONTENT_TYPE) if response_without_body
          [@status, @headers, @body]
        end

        protected

        def response_without_body
          ::Rack::Utils::STATUS_WITH_NO_ENTITY_BODY.include? @status
        end

        def rack_release_enforcing_content_type
          ::Rack.release < ONE_FIVE
        end
      end

      # Wraps the Rack input so it can be treated like a String or
      # Enumerable.
      # @api private
      class RequestBody
        # @param [Rack::Request] request the Rack request
        def initialize(request)
          @request = request
        end

        # Rack Servers differ in the way you can access their request bodys.
        # While some allow you to directly get a Ruby IO object others don't.
        # You have to check the methods they expose, like #gets, #read, #each, #rewind and maybe others.
        # See: https://github.com/rack/rack/blob/rack-1.5/lib/rack/lint.rb#L296
        # @return [IO] the request body
        def to_io
          @request.body
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
            @value.each { |chunk| yield chunk }
          else
            @value = []
            @request.body.each { |chunk|
              @value << chunk
              yield chunk
            }
          end
        end
      end # class RequestBody
    end # class Rack
  end # module Adapters
end # module Webmachine
