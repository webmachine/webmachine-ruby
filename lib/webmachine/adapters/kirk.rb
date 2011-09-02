require 'java'
require 'kirk'
require 'uri'
require 'webmachine/version'
require 'webmachine/headers'
require 'webmachine/request'
require 'webmachine/response'
require 'webmachine/dispatcher'

module Webmachine
  module Adapters
    # An adapter for the kirk JRuby webserver.
    module Kirk
      def self.run
        connector = ::Kirk::Jetty::SelectChannelConnector.new.tap do |conn|
          conn.set_host('0.0.0.0')
          conn.set_port(3000)
        end

        server = ::Kirk::Server.new(Handler.new, :connectors => [connector])

        trap(:INT) { server.stop }

        server.start
        server.join
      end

      class Handler < ::Kirk::Jetty::AbstractHandler
        java_import 'java.util.zip.GZIPInputStream'
        java_import 'java.util.zip.InflaterInputStream'

        # Trigger the autoload so that the first access to the class
        # does not happen in a thread.
        ::Kirk::InputStream

        CONTENT_LENGTH_TYPE_REGEXP = /^Content-(?:Type|Length)$/i
        CONTENT_LENGTH_RESP = 'Content-Length'
        CONTENT_TYPE_RESP = 'Content-Type'

        SERVER_STRING = [Webmachine::SERVER_STRING, ::Kirk::NAME, ::Kirk::VERSION].join(' ')

        def handle(target, base_wreq, wreq, wres)
          begin
            header = http_headers(wreq, Webmachine::Headers.new)
            body = request_body(wreq)

            request = Webmachine::Request.new(wreq.get_method || 'GET',
                                              URI.parse(wreq.getRequestURI),
                                              header,
                                              body.read)
            response = Webmachine::Response.new
            Webmachine::Dispatcher.dispatch(request, response)

            wres.set_status(response.code.to_i)
            wres.add_header('Server', SERVER_STRING)

            set_response_header(response.headers, wres)

            buffer = wres.get_output_stream

            case response.body
            when String
              buffer.write(response.body.to_java_bytes)
            when Enumerable
              response.body.each do |chunk|
                buffer.write(chunk.to_java_bytes)
              end
            else
              if response.body.respond_to?(:call)
                buffer.write(response.body.call.to_java_bytes)
              end
            end
          ensure
            body.recycle if body.respond_to?(:recycle)
            wreq.set_handled(true)
          end
        end

        def http_headers(env, headers)
          env.get_header_names.each do |name|
            value = env.get_header(name) || ''

            headers[name] = value unless headers[name] || value == ''
          end
          headers
        end

        def request_body(wreq)
          input = wreq.get_input_stream

          case wreq.get_header('Content-Encoding')
          when 'deflate'
            input = InflaterInputStream.new(input)
          when 'gzip'
            input = GZIPInputStream.new(input)
          end

          ::Kirk::InputStream.new(input)
        end

        def set_response_header(headers, response)
          headers.each do |k, vs|
            vs.split("\n").each do |v|
              case k
              when CONTENT_TYPE_RESP
                response.set_content_type(v)
              when CONTENT_LENGTH_RESP
                response.set_content_length(v.to_i)
              else
                response.add_header(k, v)
              end
            end
          end
        end
      end
    end
  end
end
