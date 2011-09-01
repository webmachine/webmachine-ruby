require 'mongrel'
require 'uri'
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
        config = ::Mongrel::Configurator.new(:port => 3000) do
          listener do
            uri '/', :handler => Webmachine::Adapters::Mongrel::Handler.new
          end
          trap('INT') { stop }
          run
        end
        config.join
      end

      class Handler < ::Mongrel::HttpHandler
        def process(req, res)
          header = Webmachine::Headers.new
          req.params.each {|k, v| header[k] = v }
          request = Webmachine::Request.new(req.params['REQUEST_METHOD'],
                                            URI.parse(req.params['REQUEST_URI']),
                                            header,
                                            req.body.read)
          response = Webmachine::Response.new
          Webmachine::Dispatcher.dispatch(request, response)

          res.start(response.code.to_i) do |head, output|
            response.headers.each {|k, v| head[k] = v }
            head['Server'] = "#{Webmachine::SERVER_STRING} mongrel/#{::Mongrel::Const::MONGREL_VERSION}"

            case response.body
            when String
              output << response.body
            when Enumerable
              response.body.each {|part| output << part }
            else
              if response.body.respond_to?(:call)
                output << response.body.call
              end
            end
          end
        end
      end
    end
  end
end
