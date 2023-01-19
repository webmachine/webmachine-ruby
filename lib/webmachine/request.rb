require 'cgi'
require 'forwardable'
require 'webmachine/constants'
require 'ipaddr'

module Webmachine
  # Request represents a single HTTP request sent from a client. It
  # should be instantiated by {Adapters} when a request is received
  class Request
    HTTP_HEADERS_MATCH = /^(?:[a-z0-9])+(?:_[a-z0-9]+)*$/i.freeze
    ROUTING_PATH_MATCH = /^\/(.*)/.freeze

    extend Forwardable

    attr_reader :method, :uri, :headers, :body, :routing_tokens, :base_uri
    attr_accessor :disp_path, :path_info, :path_tokens

    # @param [String] method the HTTP request method
    # @param [URI] uri the requested URI, including host, scheme and
    #   port
    # @param [Headers] headers the HTTP request headers
    # @param [String,#to_s,#each,nil] body the entity included in the
    #   request, if present
    def initialize(method, uri, headers, body, routing_tokens = nil, base_uri = nil)
      @method, @headers, @body = method, headers, body
      @uri = build_uri(uri, headers)
      @routing_tokens = routing_tokens || @uri.path.match(ROUTING_PATH_MATCH)[1].split(SLASH)
      @base_uri = base_uri || @uri.dup.tap do |u|
        u.path = SLASH
        u.query = nil
      end
    end

    def_delegators :headers, :[]

    # Enables quicker access to request headers by using a
    # lowercased-underscored version of the header name, e.g.
    # `if_unmodified_since`.
    def method_missing(m, *args, &block)
      if HTTP_HEADERS_MATCH.match?(m)
        # Access headers more easily as underscored methods.
        header_name = m.to_s.tr(UNDERSCORE, DASH)
        if (header_value = @headers[header_name])
          # Make future lookups faster.
          self.class.class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{m}
            @headers["#{header_name}"]
          end
          RUBY
        end
        header_value
      else
        super
      end
    end

    # @return[true, false] Whether the request body is present.
    def has_body?
      !(body.nil? || body.empty?)
    end

    # Returns a hash of query parameters (they come after the ? in the
    # URI). Note that this does NOT work in the same way as Rails,
    # i.e. it does not support nested arrays and hashes.
    # @return [Hash] query parameters
    def query
      unless @query
        @query = {}
        (uri.query || '').split('&').each do |kv|
          key, value = kv.split('=')
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
      @cookies ||= Webmachine::Cookie.parse(headers['Cookie'])
      @cookies
    end

    # Is this an HTTPS request?
    #
    # @return [Boolean]
    #   true if this request was made via HTTPS
    def https?
      uri.scheme == 'https'
    end

    # Is this a GET request?
    #
    # @return [Boolean]
    #   true if this request was made with the GET method
    def get?
      method == GET_METHOD
    end

    # Is this a HEAD request?
    #
    # @return [Boolean]
    #   true if this request was made with the HEAD method
    def head?
      method == HEAD_METHOD
    end

    # Is this a POST request?
    #
    # @return [Boolean]
    #   true if this request was made with the GET method
    def post?
      method == POST_METHOD
    end

    # Is this a PUT request?
    #
    # @return [Boolean]
    #   true if this request was made with the PUT method
    def put?
      method == PUT_METHOD
    end

    # Is this a DELETE request?
    #
    # @return [Boolean]
    #   true if this request was made with the DELETE method
    def delete?
      method == DELETE_METHOD
    end

    # Is this a TRACE request?
    #
    # @return [Boolean]
    #   true if this request was made with the TRACE method
    def trace?
      method == TRACE_METHOD
    end

    # Is this a CONNECT request?
    #
    # @return [Boolean]
    #   true if this request was made with the CONNECT method
    def connect?
      method == CONNECT_METHOD
    end

    # Is this an OPTIONS request?
    #
    # @return [Boolean]
    #   true if this request was made with the OPTIONS method
    def options?
      method == OPTIONS_METHOD
    end

    private

    IPV6_MATCH = /\A\[(?<address> .* )\]:(?<port> \d+ )\z/x.freeze  # string like "[::1]:80"
    HOST_MATCH = /\A(?<host> [^:]+ ):(?<port> \d+ )\z/x.freeze      # string like "www.example.com:80"

    def parse_host(uri, host_string)
      # Split host and port number from string.
      case host_string
      when IPV6_MATCH
        uri.host = IPAddr.new($~[:address], Socket::AF_INET6).to_s
        uri.port = $~[:port].to_i
      when HOST_MATCH
        uri.host = $~[:host]
        uri.port = $~[:port].to_i
      else # string with no port number
        uri.host = host_string
      end

      uri
    end

    def build_uri(uri, headers)
      uri = URI(uri)
      uri.port ||= 80
      uri.scheme ||= HTTP
      if uri.host
        return uri
      end

      parse_host(uri, headers.fetch(HOST))
    end
  end # class Request
end # module Webmachine
