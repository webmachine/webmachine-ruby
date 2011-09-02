require 'webrick'
require 'webmachine/version'
require 'webmachine/headers'
require 'webmachine/request'
require 'webmachine/response'
require 'webmachine/dispatcher'

module Webmachine
  module Adapters
    # Connects Webmachine to WEBrick.
    module WEBrick
      # Starts the WEBrick adapter
      def self.run
        server = Webmachine::Adapters::WEBrick::Server.new :Port => 3000
        trap("INT"){ server.shutdown }
        Thread.new { server.start }.join
      end

      class Server < ::WEBrick::HTTPServer
        def service(wreq, wres)
          header = Webmachine::Headers.new
          wreq.each {|k,v| header[k] = v }
          request = Webmachine::Request.new(wreq.request_method,
                                            wreq.request_uri,
                                            header,
                                            RequestBody.new(wreq))
          response = Webmachine::Response.new
          Webmachine::Dispatcher.dispatch(request, response)
          wres.status = response.code.to_i
          response.headers.each do |k,v|
            wres[k] = v
          end
          wres['Server'] = [Webmachine::SERVER_STRING, wres.config[:ServerSoftware]].join(" ")
          case response.body
          when String
            wres.body << response.body
          when Enumerable
            response.chunked = true if response.respond_to?(:chunked)
            response.body.each {|part| wres.body << part }
          else
            if response.body.respond_to?(:call)
              response.chunked = true if response.respond_to?(:chunked)
              wres.body << response.body.call
            end
          end
        end
      end

      # Wraps the WEBrick request body so that it can be passed to
      # {Request} while still lazily evaluating the body.
      class RequestBody
        def initialize(request)
          @request = request
        end

        # Converts the body to a String so you can work with the entire
        # thing.
        def to_s
          @value ? @value.join : @request.body
        end

        # Iterates over the body in chunks. If the body has previously
        # been read, this method can be called again and get the same
        # sequence of chunks.
        # @yield [chunk]
        # @yieldparam [String] chunk a chunk of the request body
        def each
          if @value
            @value.each {|chunk| yield chunk }
          else
            @value = []
            @request.body {|chunk| @value << chunk; yield chunk }
          end
        end
      end
    end
  end
end
