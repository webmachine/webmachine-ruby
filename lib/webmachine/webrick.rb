require 'webrick'
require 'webmachine/version'
require 'webmachine/request'
require 'webmachine/response'
require 'webmachine/dispatcher'

module Webmachine
  module WEBrick
    # A simple Webmachine handler for WEBrick.
    class Handler < ::WEBrick::HTTPServlet::AbstractServlet
      def service(wreq, wres)
        header = {}
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
        # wres['Server'] = [Webmachine::SERVER_STRING, wres['Server']].join(" ")
        if response.body.respond_to?(:each)
          response.body.each {|part| wres.body << part }
        else
          wres.body << response.body
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
