require 'mongrel'
require 'webmachine/version'
require 'webmachine/headers'
require 'webmachine/request'
require 'webmachine/response'
require 'webmachine/dispatcher'

module Webmachine
  module Adapters
    # Connects Webmachine to Mongrel.
    module Mongrel
      # Starts the Mongrel adapter
      def self.run
        server = ::Mongrel::HttpServer.new('0.0.0.0', 3000)
        server.register('/', Webmachine::Adapters::Mongrel::Handler.new )
        trap("INT"){ server.stop }
        server.run.join
      end

      class Handler < ::Mongrel::HttpHandler
        def process(wreq, wres)
          header = Webmachine::Headers.new
          wreq.params.each { |k,v| header[k] = v }
          request = Webmachine::Request.new(wreq.params["REQUEST_METHOD"],
                                            URI.parse(wreq.params["REQUEST_URI"]),
                                            header,
                                            wreq.body || StringIO.new(''))

          response = Webmachine::Response.new
          Webmachine::Dispatcher.dispatch(request, response)

          begin
            wres.status = response.code.to_i
            wres.send_status(nil)

            response.headers.each { |k, vs|
              vs.split("\n").each { |v|
                wres.header[k] = v
              }
            }
            wres.header['Server'] = [Webmachine::SERVER_STRING, "Mongrel/#{::Mongrel::Const::MONGREL_VERSION}"].join(" ")
            wres.send_header

            case response.body
            when String
              wres.write response.body
              wres.socket.flush
            when Enumerable
              response.body.each { |part|
                wres.write part
                wres.socket.flush
              }
            when response.body.respond_to?(:call)
              wres.write part
              wres.socket.flush
            end
          ensure
            response.body.close if response.body.respond_to? :close
          end
        end
      end
    end
  end
end
