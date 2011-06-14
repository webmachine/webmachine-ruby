require 'webmachine/resource/callbacks'
require 'webmachine/resource/encodings'

module Webmachine
  # Resource is the primary building block of Webmachine
  # applications. It includes all of the methods you might want to
  # override to customize the behavior of the resource.  The simplest
  # resource you can implement looks like this:
  #
  #    class HelloWorldResource < Webmachine::Resource
  #      def to_html
  #        "<html><body>Hello, world!</body></html>"
  #      end
  #    end
  #
  # For more information about how response decisions are made in
  # Webmachine based on your resource class, refer to the diagram at
  # {http://webmachine.basho.com/images/http-headers-status-v3.png}.
  class Resource
    include Callbacks
    include Encodings

    attr_reader :request, :response

    # Creates a new Resource to process the request. This is called
    # internally by Webmachine when dispatching, but can also be used
    # to test resources in isolation.
    # @param [Request] request the request object
    # @param [Response] response the response object
    def initialize(request, response)
      @request, @response = request, response
    end

    private
    # When no specific charsets are provided, this acts as an identity
    # on the response body. Probably deserves some refactoring.
    def charset_nop(x)
      x
    end
  end
end
