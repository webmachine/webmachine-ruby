require 'reel'
require 'webmachine/version'
require 'webmachine/headers'
require 'webmachine/request'
require 'webmachine/response'
require 'webmachine/dispatcher'
require 'webmachine/chunked_body'

if defined?(JRUBY_VERSION) && JRUBY_VERSION == "1.7.3"
  Celluloid.task_class = Celluloid::TaskThread
end

module Webmachine
  module Adapters
    class Reel < Adapter
      def run
        options = {
          :port => configuration.port,
          :host => configuration.ip
        }.merge(configuration.adapter_options)

        @server = ::Reel::Server.supervise(options[:host], options[:port], &method(:process))
        trap("INT") { shutdown }
        sleep
      end

      def shutdown
        @server.terminate
      end

      def process(connection)
        while wreq = connection.request
          case wreq
          when ::Reel::Request
            header = Webmachine::Headers[wreq.headers.dup]
            host_parts = header.fetch('Host').split(':')
            path_parts = wreq.url.split('?')
            requri = URI::HTTP.build({}.tap do |h|
              h[:host] = host_parts.first
              h[:port] = host_parts.last.to_i if host_parts.length == 2
              h[:path] = path_parts.first
              h[:query] = path_parts.last if path_parts.length == 2
            end)
            request = Webmachine::Request.new(wreq.method.to_s.upcase,
                                              requri,
                                              header,
                                              LazyRequestBody.new(wreq))
            response = Webmachine::Response.new
            @dispatcher.dispatch(request,response)

            # Reel doesn't support Callable bodies, so convert to Enumerable
            body = if response.body.respond_to?(:call)
                     Array(response.body.call)
                   else
                     response.body
                   end

            # Reel doesn't support array-valued header hashes
            headers = response.headers.flattened(", ")

            connection.respond ::Reel::Response.new(response.code, headers, body)
          when ::Reel::WebSocket
            handler = configuration.adapter_options[:websocket_handler]
            handler.call(wreq) if handler
          end
        end
      end
    end
  end
end
