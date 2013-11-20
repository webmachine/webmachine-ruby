require 'cgi'
require 'forwardable'

module Webmachine
  # Request represents a single HTTP request sent from a client. It
  # should be instantiated by {Adapters} when a request is received
  class Request
    extend Forwardable
    attr_reader :method, :uri, :headers, :body
    attr_accessor :disp_path, :path_info, :path_tokens

    STANDARD_HTTP_METHODS = %w[GET HEAD POST PUT DELETE TRACE CONNECT OPTIONS]

    # @param [String] method the HTTP request method
    # @param [URI] uri the requested URI, including host, scheme and
    #   port
    # @param [Headers] headers the HTTP request headers
    # @param [String,#to_s,#each,nil] body the entity included in the
    #   request, if present
    def initialize(method, uri, headers, body)
      @method, @uri, @headers, @body = method, uri, headers, body
    end

    def_delegators :headers, :[]

    # Enables quicker access to request headers by using a
    # lowercased-underscored version of the header name, e.g.
    # `if_unmodified_since`.
    def method_missing(m, *args, &block)
      if m.to_s =~ /^(?:[a-z0-9])+(?:_[a-z0-9]+)*$/i
        # Access headers more easily as underscored methods.
        self[m.to_s.tr('_', '-')]
      else
        super
      end
    end

    # @return[true, false] Whether the request body is present.
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
        (uri.query || '').split(/&/).each do |kv|
          key, value = kv.split(/=/)
          if key && value
            key, value = CGI.unescape(key), CGI.unescape(value)
            @query[key] = value
          end
        end
      end
      @query
    end

    # The cookies sent in the request.
    #
    # @return [Hash]
    #   {} if no Cookies header set
    def cookies
      unless @cookies
        @cookies = Webmachine::Cookie.parse(headers['Cookie'])
      end
      @cookies
    end

    # Is this an HTTPS request?
    #
    # @return [Boolean]
    #   true if this request was made via HTTPS
    def https?
      uri.scheme == "https"
    end

    # Is this a GET request?
    #
    # @return [Boolean]
    #   true if this request was made with the GET method
    def get?
      method == "GET"
    end

    # Is this a HEAD request?
    #
    # @return [Boolean]
    #   true if this request was made with the HEAD method
    def head?
      method == "HEAD"
    end

    # Is this a POST request?
    #
    # @return [Boolean]
    #   true if this request was made with the GET method
    def post?
      method == "POST"
    end

    # Is this a PUT request?
    #
    # @return [Boolean]
    #   true if this request was made with the PUT method
    def put?
      method == "PUT"
    end

    # Is this a PATCH request?
    #
    # @return [Boolean]
    #   true if this request was made with the PUT method
    def patch?
      method == "PATCH"
    end

    # Is this a DELETE request?
    #
    # @return [Boolean]
    #   true if this request was made with the DELETE method
    def delete?
      method == "DELETE"
    end

    # Is this a TRACE request?
    #
    # @return [Boolean]
    #   true if this request was made with the TRACE method
    def trace?
      method == "TRACE"
    end

    # Is this a CONNECT request?
    #
    # @return [Boolean]
    #   true if this request was made with the CONNECT method
    def connect?
      method == "CONNECT"
    end

    # Is this an OPTIONS request?
    #
    # @return [Boolean]
    #   true if this request was made with the OPTIONS method
    def options?
      method == "OPTIONS"
    end

  end # class Request
end # module Webmachine
