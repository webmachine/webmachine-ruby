require 'reel'
require 'webmachine/version'
require 'webmachine/headers'
require 'webmachine/request'
require 'webmachine/response'
require 'webmachine/dispatcher'
require 'set'

module Webmachine
  module Adapters
    class ReelConnectionHandler
      include Celluloid

      attr_reader :dispatcher, :options, :extra_verbs

      def initialize(dispatcher, options, extra_verbs)
        @dispatcher, @options, @extra_verbs = dispatcher, options, extra_verbs
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

      def process_request(request)
        if request.websocket?
          if handler = options[:websocket_handler]
            handler.call(request.websocket)
          else
            # Pretend we don't know anything about the WebSocket protocol
            # FIXME: This isn't strictly what RFC 6455 would have us do
            request.respond :bad_request, "WebSockets not supported"
          end

          return request
        end

        # Optional support for e.g. WebDAV verbs not included in Webmachine's
        # state machine. Do the "Railsy" thing and handle them like POSTs
        # with a magical parameter
        if extra_verbs.include?(request.method)
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
        dispatcher.dispatch(wm_request, wm_response)

        fixup_headers(wm_response)
        fixup_callable_encoder(wm_response)

        request.respond ::Reel::Response.new(wm_response.code,
                                             wm_response.headers,
                                             wm_response.body)
      end

      def process_connection(connection)
        connection.each_request do |request|
          process_request(request)
        end
      rescue Reel::SocketError
        connection.close
      end
    end

    class Reel < Adapter
      def run
        options = {
          port: configuration.port,
          host: configuration.ip
        }.merge(configuration.adapter_options)

        if options[:extra_verbs]
          extra_verbs = Set.new(options[:extra_verbs].map(&:to_s).map(&:upcase))
        else
          extra_verbs = Set.new
        end

        if options[:reel_pool]
          Celluloid::Actor[:reel_webmachine_connection_handler] = ReelConnectionHandler.pool(size: options[:reel_pool_size] || Celluloid.cores, args: [dispatcher, options, extra_verbs])
        else
          ReelConnectionHandler.supervise_as(:reel_webmachine_connection_handler, dispatcher, options, extra_verbs)
        end
        connectionCallback = proc do |connection|
          connection.detach
          Celluloid::Actor[:reel_webmachine_connection_handler].async.process_connection(connection)
        end
        ::Reel::Server.supervise_as(:reel_webmachine_server, options[:host], options[:port], &connectionCallback)

        # FIXME: this will no longer work on Ruby 2.0. We need Celluloid.trap
        trap("INT") { Celluloid::Actor[:reel_webmachine_server].terminate; exit 0 }
        Celluloid::Actor.join(Celluloid::Actor[:reel_webmachine_server])
      end

      def shutdown
        Celluloid::Actor[:reel_webmachine_server].terminate! if Celluloid::Actor[:reel_webmachine_server]
      end
    end
  end
end
