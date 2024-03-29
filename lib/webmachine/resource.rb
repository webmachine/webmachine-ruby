require 'webmachine/resource/callbacks'
require 'webmachine/resource/encodings'
require 'webmachine/resource/entity_tags'
require 'webmachine/resource/authentication'
require 'webmachine/resource/tracing'

module Webmachine
  # Resource is the primary building block of Webmachine applications,
  # and describes families of HTTP resources. It includes all of the
  # methods you might want to override to customize the behavior of
  # the resource.  The simplest resource family you can implement
  # looks like this:
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
    include EntityTags
    include Tracing

    attr_reader :request, :response

    # Creates a new {Resource}, initializing it with the request and
    # response. Note that you may still override the `initialize` method to
    # initialize your resource. It will be called after the request
    # and response ivars are set.
    # @param [Request] request the request object
    # @param [Response] response the response object
    # @return [Resource] the new resource
    def self.new(request, response)
      instance = allocate
      instance.instance_variable_set(:@request, request)
      instance.instance_variable_set(:@response, response)
      instance.send :initialize
      instance
    end

    #
    # Starts a web server that serves requests for a subclass of
    # Webmachine::Resource.
    #
    # @return [void]
    #
    def self.run
      resource = self
      Application.new do |app|
        app.routes do |router|
          router.add [:*], resource
        end
      end.run
    end

    private

    # When no specific charsets are provided, this acts as an identity
    # on the response body. Probably deserves some refactoring.
    def charset_nop(x)
      x
    end
  end # class Resource
end # module Webmachine
