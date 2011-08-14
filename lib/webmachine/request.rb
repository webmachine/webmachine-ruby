require 'forwardable'

module Webmachine
  # This represents a single HTTP request sent from a client.
  class Request
    extend Forwardable
    attr_reader :method, :uri, :headers, :body
    attr_accessor :disp_path, :path_info, :path_tokens

    def initialize(meth, uri, headers, body)
      @method, @uri, @headers, @body = meth, uri, headers, body
    end

    def_delegators :headers, :[]

    # @private
    def method_missing(m, *args)
      if m.to_s =~ /^(?:[a-z0-9])+(?:_[a-z0-9]+)*$/i
        # Access headers more easily as underscored methods.
        self[m.to_s.tr('_', '-')]
      else
        super
      end
    end

    # Whether the request body is present.
    def has_body?
      !(body.nil? || body.empty?)
    end
    
    # The root URI for the request, ignoring path and query. This is
    # useful for calculating relative paths to resources.
    # @return [URI]
    def base_uri
      @base_uri ||= uri.dup.tap do |u|
        u.path = "/"
        u.query = nil
      end
    end

    # Returns a hash of query parameters (they come after the ? in the
    # URI). Note that this does NOT work in the same way as Rails,
    # i.e. it does not support nested arrays and hashes.
    # @return [Hash] query parameters
    def query
      unless @query
        @query = {}
        uri.query.split(/&/).each do |kv|
          k, v = URI.unescape(kv).split(/=/)
          @query[k] = v if k && v
        end
      end
      @query
    end
  end
end
