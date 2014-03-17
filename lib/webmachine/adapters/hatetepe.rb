require 'hatetepe/server'

unless Hatetepe::VERSION >= '0.5.0'
  raise LoadError, 'webmachine only supports hatetepe >= 0.5.0'
end

require 'webmachine/version'
require 'webmachine/headers'
require 'webmachine/request'
require 'webmachine/response'
require 'webmachine/dispatcher'
require 'webmachine/chunked_body'

module Webmachine
  module Adapters
    class Hatetepe < Adapter
      def options
        {
          :host => application.configuration.ip,
          :port => application.configuration.port,
          :app  => [
            ::Hatetepe::Server::Pipeline,
            ::Hatetepe::Server::KeepAlive,
            method(:call)
          ]
        }
      end

      def run
        EM.epoll
        EM.synchrony do
          ::Hatetepe::Server.start(options)
          trap("INT") { shutdown }
        end
      end

      def shutdown
        EM.stop
      end

      def call(request, &respond)
        response = Webmachine::Response.new
        application.dispatcher.dispatch(convert_request(request), response)

        respond.call(convert_response(response))
      end

      private

      def convert_request(request)
        args = [
          request.verb,
          build_request_uri(request),
          Webmachine::Headers[request.headers.dup],
          Body.new(request.body)
        ]
        Webmachine::Request.new(*args)
      end

      def convert_response(response)
        response.headers["Server"] = [
          Webmachine::SERVER_STRING,
          "hatetepe/#{::Hatetepe::VERSION}"
        ].join(" ")

        args = [
          response.code.to_i,
          response.headers,
          convert_body(response.body)
        ]
        ::Hatetepe::Response.new(*args)
      end

      def convert_body(body)
        if body.respond_to?(:call)
          [ body.call ]
        elsif body.respond_to?(:to_s)
          [ body.to_s ]
        else
          body
        end
      end

      def build_request_uri(request)
        uri = URI.parse(request.uri)
        uri.scheme = "http"

        host     = request.headers.fetch("Host", "").split(":")
        uri.host = host[0]      || configuration.ip
        uri.port = host[1].to_i || configuration.port

        URI.parse(uri.to_s)
      end

      class Body < Struct.new(:body)
        def each(&block)
          body.rewind
          body.each(&block)
        end

        def to_s
          body.rewind
          body.read.to_s
        end
      end
    end
  end
end
