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
        c = Webmachine.configuration
        options = {
          :port => c.port,
          :host => c.ip
        }.merge(c.adapter_options)
        config = ::Mongrel::Configurator.new(options) do
          listener do
            uri '/', :handler => Webmachine::Adapters::Mongrel::Handler.new
          end
          trap("INT") { stop }
          run
        end
        config.join
      end

      class Handler < ::Mongrel::HttpHandler
        def process(wreq, wres)
          header = http_headers(wreq.params, Webmachine::Headers.new)

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
            else
              if response.body.respond_to?(:call)
                wres.write part
                wres.socket.flush
              end
            end
          ensure
            response.body.close if response.body.respond_to? :close
          end
        end

        def http_headers(env, headers)
          env.inject(headers) do |h,(k,v)|
            if k =~ /^HTTP_(\w+)$/
              h[$1.tr("_", "-")] = v
            end
            h
          end
        end
      end
    end
  end
end
