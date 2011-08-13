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
        uri.query.split("&").each do |kv|
          k, v = URI.unescape(kv).match(/^(.*)=(.*)$/)[0..1]
          @query[k] = v if k && v
        end
      end
      @query
    end
  end
end
