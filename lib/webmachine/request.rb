require 'forwardable'
module Webmachine
  # This represents a single HTTP request sent from a client.
  class Request
    extend Forwardable
    attr_reader :method, :uri, :headers, :body
    
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
  end
end
