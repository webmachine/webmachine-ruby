require 'forwardable'
module Webmachine
  # This represents a single HTTP request sent from a client.
  class Request
    extend Forwardable
    attr_reader :method, :uri, :headers, :body
    attr_accessor :disp_path
    
    def initialize(meth, uri, headers, body)
      @method, @uri, @headers, @body = meth, uri, headers, body
    end
    
    delegate :[] => :headers
    
    # @private
    def method_missing(m, *args)
      if m.to_s =~ /^(?:[a-z]_)+[a-z]+$/i
        # Access headers more easily as underscored methods.
        headers[m.to_s.tr('_', '-')]
      else
        super
      end
    end    

    # The root URI for the request, ignoring path and query. This is
    # useful for calculating relative paths to resources.
    def base_uri
      @base_uri ||= uri.dup.tap do |u|
        u.path = "/"
        u.query = nil
      end
    end
  end
end
