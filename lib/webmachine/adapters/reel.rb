require 'reel'
require 'webmachine/version'
require 'webmachine/headers'
require 'webmachine/request'
require 'webmachine/response'
require 'webmachine/dispatcher'
require 'webmachine/chunked_body'

module Webmachine
  module Adapters
    class Reel < Adapter
      def run
        options = {
          :port => configuration.port,
          :host => configuration.ip
        }.merge(configuration.adapter_options)
        server = ::Reel::Server.supervise(options[:host], options[:port], &method(:process))
        trap("INT"){ server.terminate; exit 0 }
        sleep
      end

      def process(connection)
        if wreq = connection.request
          header = Webmachine::Headers[wreq.headers.dup]
          requri = URI::HTTP.build(:host => header.fetch('Host').split(':').first,
                                 :port => header.fetch('Host').split(':').last.to_i,
                                 :path => wreq.url.split('?').first,
                                 :query => wreq.url.split('?').last)
          request = Webmachine::Request.new(wreq.method.to_s.upcase,
                                            requri,
                                            header,
                                            LazyRequestBody.new(wreq))
          response = Webmachine::Response.new
          @dispatcher.dispatch(request,response)
          # TODO: Chunked encoding support? This completely misses the
          # opportunity to stream efficiently.
          body = case response.body
                 when String
                   response.body
                 when Enumerable
                   response.body.to_a.join
                 end
          wres = ::Reel::Response.new(response.code, response.headers, body)
          connection.respond(wres)
        end
      end
    end
  end
end
