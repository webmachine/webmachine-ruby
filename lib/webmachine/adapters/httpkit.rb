require 'webmachine/adapter'
require 'webmachine/constants'
require 'webmachine/version'
require 'httpkit'
require 'webmachine/version'
require 'webmachine/response'
require 'webmachine/request'
require 'webmachine/headers'

module Webmachine
  module Adapters
    class HTTPkit < Adapter
      include Constants

      VERSION_STRING = "#{Webmachine::SERVER_STRING} HTTPkit/#{::HTTPkit::VERSION}".freeze

      def options
        @options ||= {
          :address => application.configuration.ip,
          :port => application.configuration.port,
          :handlers => [
            ::HTTPkit::Server::TimeoutsHandler.new,
            ::HTTPkit::Server::KeepAliveHandler.new,
            self
          ]
        }
      end

      def run
        ::HTTPkit.start do
          ::HTTPkit::Server.start(options)
        end
      end

      # Called by HTTPkit::Server for every request
      def serve(request, served)
        response = Webmachine::Response.new
        application.dispatcher.dispatch(convert_request(request), response)

        served.fulfill(convert_response(response))
      end

      private

      # Converts HTTPkit::Request to Webmachine::Request
      def convert_request(request)
        Webmachine::Request.new(
          request.http_method.to_s.upcase,
          request.uri,
          Webmachine::Headers[request.headers.dup],
          request.body)
      end

      # Converts Webmachine::Response to HTTPkit::Response
      def convert_response(response)
        response.headers[SERVER] = VERSION_STRING


        ::HTTPkit::Response.new(
          response.code.to_i,
          response.headers,
          convert_body(response.body))
      end

      # HTTPkit::Body accepts strings and enumerables, i.e. Webmachine's
      # Callable, Enumerable, IO, and Fiber encoders are supported.
      def convert_body(body)
        if body.respond_to?(:call)
          [body.call]
        else
          body || ''
        end
      end
    end
  end
end
