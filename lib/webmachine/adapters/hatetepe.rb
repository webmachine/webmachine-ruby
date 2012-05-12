require 'hatetepe/server'
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
          :host => configuration.ip,
          :port => configuration.port,
          :app  => [
            ::Hatetepe::Server::Pipeline,
            ::Hatetepe::Server::KeepAlive,
            method(:call)
          ]
        }
      end

      def run
        EM.synchrony do
          ::Hatetepe::Server.start(options)
          trap("INT") { EM.stop }
        end
      end

      def call(request, &respond)
        response = Webmachine::Response.new
        dispatcher.dispatch(convert_request(request), response)

        respond.call(convert_response(response))
      end

      def convert_request(request)
        args = [
          request.verb,
          URI.parse(request.uri),
          Webmachine::Headers[request.headers.map {|k, v| [k.downcase, v] }],
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
