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
        options = {
          :port => configuration.port,
          :host => configuration.ip
        }.merge(configuration.adapter_options)
        config = ::Mongrel::Configurator.new(options) do
          listener do
            uri '/', :handler => Webmachine::Adapters::Mongrel::Handler.new(dispatcher)
          end
          trap("INT") { stop }
          run
        end
        config.join
      end

      # A Mongrel handler for Webmachine
      class Handler < ::Mongrel::HttpHandler
        def initialize(dispatcher)
          @dispatcher = dispatcher
          super
        end

        # Processes an individual request from Mongrel through Webmachine.
        def process(wreq, wres)
          header = Webmachine::Headers.from_cgi(wreq.params)

          request = Webmachine::Request.new(wreq.params["REQUEST_METHOD"],
                                            URI.parse(wreq.params["REQUEST_URI"]),
                                            header,
                                            RequestBody.new(wreq))

          response = Webmachine::Response.new
          @dispatcher.dispatch(request, response)

          begin
            wres.status = response.code.to_i
            wres.send_status(nil)

            response.headers.each { |k, vs|
              vs.split("\n").each { |v|
                wres.header[k] = v
              }
            }
            wres.header['Server'] = [Webmachine::SERVER_STRING, "Mongrel/#{::Mongrel::Const::MONGREL_VERSION}"].join(" ")
            wres.send_header

            case response.body
            when String
              wres.write response.body
              wres.socket.flush
            when Enumerable
              Webmachine::ChunkedBody.new(response.body).each { |part|
                wres.write part
                wres.socket.flush
              }
            else
              if response.body.respond_to?(:call)
                Webmachine::ChunkedBody.new(Array(response.body.call)).each { |part|
                  wres.write part
                  wres.socket.flush
                }
              end
            end
          ensure
            response.body.close if response.body.respond_to? :close
          end
        end
      end # class Handler

      class RequestBody
        attr_reader :request

        def initialize(request)
          @request = request
        end

        def to_s
          request.body.rewind
          request.body.read
        end

        def each(&block)
          request.body.each(&block)
        end
      end # class RequestBody

    end # module Mongrel
  end # module Adapters
end # module Webmachine
