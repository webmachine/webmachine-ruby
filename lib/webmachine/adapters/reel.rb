require 'reel'
require 'webmachine/version'
require 'webmachine/headers'
require 'webmachine/request'
require 'webmachine/response'
require 'webmachine/dispatcher'
require 'set'

module Webmachine
  module Adapters
    class Reel < Adapter
      # Used to override default Reel server options (useful in testing)
      DEFAULT_OPTIONS = {}

      def run
        @options = DEFAULT_OPTIONS.merge({
          :port => application.configuration.port,
          :host => application.configuration.ip
        }).merge(application.configuration.adapter_options)

        if extra_verbs = application.configuration.adapter_options[:extra_verbs]
          @extra_verbs = Set.new(extra_verbs.map(&:to_s).map(&:upcase))
        else
          @extra_verbs = Set.new
        end

        @server = ::Reel::Server.supervise(@options[:host], @options[:port], &method(:process))

        # FIXME: this will no longer work on Ruby 2.0. We need Celluloid.trap
        trap("INT") { @server.terminate; exit 0 }
        Celluloid::Actor.join(@server)
      end

      def shutdown
        @server.terminate! if @server
      end

      def process(connection)
        connection.each_request do |request|
          # Users of the adapter can configure a custom WebSocket handler
          if request.websocket?
            if handler = @options[:websocket_handler]
              handler.call(request.websocket)
            else
              # Pretend we don't know anything about the WebSocket protocol
              # FIXME: This isn't strictly what RFC 6455 would have us do
              request.respond :bad_request, "WebSockets not supported"
            end

            next
          end

          # Optional support for e.g. WebDAV verbs not included in Webmachine's
          # state machine. Do the "Railsy" thing and handle them like POSTs
          # with a magical parameter
          if @extra_verbs.include?(request.method)
            method = "POST"
            param  = "_method=#{request.method}"
            uri    = request_uri(request.url, request.headers, param)
          else
            method = request.method
            uri    = request_uri(request.url, request.headers)
          end

          wm_headers  = Webmachine::Headers[request.headers.dup]
          wm_request  = Webmachine::Request.new(method, uri, wm_headers, request.body)

          wm_response = Webmachine::Response.new
          application.dispatcher.dispatch(wm_request, wm_response)

          fixup_headers(wm_response)
          fixup_callable_encoder(wm_response)

          request.respond ::Reel::Response.new(wm_response.code,
                                               wm_response.headers,
                                               wm_response.body)
        end
      end

      def request_uri(path, headers, extra_query_params = nil)
        host_parts = headers.fetch('Host').split(':')
        path_parts = path.split('?')

        uri_hash = {host: host_parts.first, path: path_parts.first}

        uri_hash[:port]  = host_parts.last.to_i if host_parts.length == 2
        uri_hash[:query] = path_parts.last      if path_parts.length == 2

        if extra_query_params
          if uri_hash[:query]
            uri_hash[:query] << "&#{extra_query_params}"
          else
            uri_hash[:query] = extra_query_params
          end
        end

        URI::HTTP.build(uri_hash)
      end

      def fixup_headers(response)
        response.headers.each do |key, value|
          if value.is_a?(Array)
            response.headers[key] = value.join(", ")
          end
        end
      end

      def fixup_callable_encoder(response)
        if response.body.is_a?(Streaming::CallableEncoder)
          response.body = [response.body.call]
        end
      end
    end
  end
end
