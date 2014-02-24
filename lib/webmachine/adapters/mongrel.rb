require 'mongrel'
require 'webmachine/version'
require 'webmachine/headers'
require 'webmachine/request'
require 'webmachine/response'
require 'webmachine/dispatcher'
require 'webmachine/chunked_body'

module Webmachine
  module Adapters
    # Connects Webmachine to Mongrel.
    class Mongrel < Adapter

      # Starts the Mongrel adapter
      def run
        defaults = {
          :port => application.configuration.port,
          :host => application.configuration.ip,
          :application => application
        }.merge(application.configuration.adapter_options)
        @config = ::Mongrel::Configurator.new(defaults) do
          listener do
            uri '/', :handler => Webmachine::Adapters::Mongrel::Handler.new(defaults[:application])
          end
          trap("INT") { stop }
          run
        end
        @config.join
      end

      def shutdown
        # The second argument tells mongrel to block until all listeners are shut down.
        # This causes the mongrel tests to be very slow, but faster methods cause errors.
        @config.stop(false, true) if @config
      end

      # A Mongrel handler for Webmachine
      class Handler < ::Mongrel::HttpHandler
        def initialize(application)
          @application = application
          super()
        end

        # Processes an individual request from Mongrel through Webmachine.
        def process(wreq, wres)
          header = Webmachine::Headers.from_cgi(wreq.params)

          request = Webmachine::Request.new(wreq.params["REQUEST_METHOD"],
                                            URI.parse(wreq.params["REQUEST_URI"]),
                                            header,
                                            RequestBody.new(wreq))

          response = Webmachine::Response.new
          @application.dispatcher.dispatch(request, response)

          begin
            wres.status = response.code.to_i
            wres.send_status(nil)

            response.headers.each do |k, vs|
              [*vs].each do |v|
                wres.header[k] = v
              end
            end

            wres.header['Server'] = [Webmachine::SERVER_STRING, "Mongrel/#{::Mongrel::Const::MONGREL_VERSION}"].join(" ")
            wres.send_header

            case response.body
            when String
              wres.write response.body
              wres.socket.flush
            when Enumerable
              # This might be an IOEncoder with a Content-Length, which shouldn't be chunked.
              if response.headers["Transfer-Encoding"] == "chunked"
                Webmachine::ChunkedBody.new(response.body).each do |part|
                  wres.write part
                  wres.socket.flush
                end
              else
                response.body.each do |part|
                  wres.write part
                  wres.socket.flush
                end
              end
            else
              if response.body.respond_to?(:call)
                Webmachine::ChunkedBody.new(Array(response.body.call)).each do |part|
                  wres.write part
                  wres.socket.flush
                end
              end
            end
          ensure
            response.body.close if response.body.respond_to? :close
          end
        end
      end # class Handler

      # Wraps a Mongrel request body so that it can behave like a
      # String.
      # @api private
      class RequestBody
        # @return the request from Mongrel
        attr_reader :request

        # @param request the request from Mongrel
        def initialize(request)
          @request = request
        end

        # @return [String] the request body as a string
        def to_s
          request.body.rewind
          request.body.read
        end

        # @yield [chunk]
        # @yieldparam [String] chunk a chunk of the request body
        def each(&block)
          request.body.each(&block)
        end
      end # class RequestBody

    end # module Mongrel
  end # module Adapters
end # module Webmachine
