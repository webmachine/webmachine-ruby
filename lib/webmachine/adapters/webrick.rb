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
      # Used to override default WEBRick options (useful in testing)
      DEFAULT_OPTIONS = {}

      # Starts the WEBrick adapter
      def run
        options = DEFAULT_OPTIONS.merge({
          :Port => application.configuration.port,
          :BindAddress => application.configuration.ip,
          :application => application
        }).merge(application.configuration.adapter_options)
        @server = Server.new(options)
        trap("INT") { shutdown }
        @server.start
      end

      def shutdown
        @server.shutdown if @server
      end

      # WEBRick::HTTPServer that is run by the WEBrick adapter.
      class Server < ::WEBrick::HTTPServer
        def initialize(options)
          @application = options[:application]
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
          @application.dispatcher.dispatch(request, response)
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
            wres.chunked = response.headers['Transfer-Encoding'] == 'chunked'
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
