require 'webrick'
require 'webmachine/version'
require 'webmachine/headers'
require 'webmachine/request'
require 'webmachine/response'
require 'webmachine/dispatcher'

module Webmachine
  module Adapters
    # Connects Webmachine to WEBrick.
    class WEBrick < Adapter

      # Starts the WEBrick adapter
      def run
        options = {
          :Port => configuration.port,
          :BindAddress => configuration.ip
        }.merge(configuration.adapter_options)
        @server = Webmachine::Adapters::WEBrick::Server.new(dispatcher, options)
        trap("INT") { shutdown }
        Thread.new { @server.start }.join
      end

      def shutdown
        @server.shutdown
      end

      # WEBRick::HTTPServer that is run by the WEBrick adapter.
      class Server < ::WEBrick::HTTPServer
        def initialize(dispatcher, options)
          @dispatcher = dispatcher
          super(options)
        end

        # Handles a request
        def service(wreq, wres)
          header = Webmachine::Headers.new
          wreq.each {|k,v| header[k] = v }
          request = Webmachine::Request.new(wreq.request_method,
                                            wreq.request_uri,
                                            header,
                                            LazyRequestBody.new(wreq))
          response = Webmachine::Response.new
          @dispatcher.dispatch(request, response)
          wres.status = response.code.to_i

          headers = response.headers.flattened.reject { |k,v| k == 'Set-Cookie' }
          headers.each { |k,v| wres[k] = v }

          cookies = [response.headers['Set-Cookie'] || []].flatten
          cookies.each { |c| wres.cookies << c }

          wres['Server'] = [Webmachine::SERVER_STRING, wres.config[:ServerSoftware]].join(" ")
          case response.body
          when String
            wres.body << response.body
          when Enumerable
            wres.chunked = true
            response.body.each {|part| wres.body << part }
          else
            if response.body.respond_to?(:call)
              wres.chunked = true
              wres.body << response.body.call
            end
          end
        end
      end # class Server
    end # module WEBrick
  end # module Adapters
end # module Webmachine
