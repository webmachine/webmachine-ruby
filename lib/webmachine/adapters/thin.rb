require 'uri'
require 'thin'
require 'webmachine/version'
require 'webmachine/headers'
require 'webmachine/request'
require 'webmachine/response'
require 'webmachine/dispatcher'
require 'webmachine/adapters/thin/backend'

module Webmachine
  module Adapters
    module Thin
      def self.run
        c = Webmachine.configuration
        options = {
          :backend => Webmachine::Adapters::Thin::Backend
        }.merge(c.adapter_options)
        EM.run do
          server = ::Thin::Server.start(c.ip, c.port, App.new, options)
        end
      end

      class App
        def call(wreq, wres)
          header = http_headers(wreq.env, Webmachine::Headers.new)
          request = Webmachine::Request.new(wreq.env['REQUEST_METHOD'],
                                            URI.parse(wreq.env['REQUEST_URI']),
                                            header,
                                            wreq.body)
          response = Webmachine::Response.new
          Webmachine::Dispatcher.dispatch(request, response)

          wres.status = response.code.to_i

          response.headers.each do |k, vs|
            vs.split("\n").each do |v|
              wres.headers[k] = v
            end
          end

          wres.headers['Server'] = [Webmachine::SERVER_STRING, ::Thin::SERVER].join(" ")
          wres.body = []

          case response.body
          when String
            wres.body = [response.body]
          when Enumerable
            # XXX Transfer-Encoding:chunked doesn't work yet. Have to investigate.
            wres.body = response.body
          else
            if response.body.respond_to?(:call)
              wres.body = response.body.call
            end
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
