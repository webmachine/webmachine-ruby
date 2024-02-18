require 'webmachine/constants'

module Webmachine
  # Case-insensitive Hash of Request headers
  class Headers < ::Hash
    CGI_HTTP_MATCH = /^HTTP_(\w+)$/.freeze
    CONTENT_TYPE_LENGTH_MATCH = /^(CONTENT_(?:TYPE|LENGTH))$/.freeze

    # Convert CGI-style Hash into Request headers
    # @param [Hash] env a hash of CGI-style env/headers
    # @return [Webmachine::Headers]
    def self.from_cgi(env)
      env.each_with_object(new) do |(k, v), h|
        if k =~ CGI_HTTP_MATCH || k =~ CONTENT_TYPE_LENGTH_MATCH
          h[$1.tr(UNDERSCORE, DASH)] = v
        end
      end
    end

    # Creates a new headers object populated with the given objects.
    # It supports the same forms as {Hash.[]}.
    #
    # @overload [](key, value, ...)
    #   Pairs of keys and values
    #   @param [Object] key
    #   @param [Object] value
    # @overload [](array)
    #   Array of key-value pairs
    #   @param [Array<Object, Object>, ...]
    # @overload [](object)
    #   Object convertible to a hash
    #   @param [Object]
    # @return [Webmachine::Headers]
    def self.[](*args)
      super(super(*args).map { |k, v| [k.to_s.downcase, v] })
    end

    # Fetch a header
    def [](key)
      super(transform_key(key))
    end

    # Set a header
    def []=(key, value)
      super(transform_key(key), value)
    end

    # Returns the value for the given key. If the key can't be found,
    # there are several options:
    # With no other arguments, it will raise a KeyError error;
    # if default is given, then that will be returned;
    # if the optional code block is specified, then that will be run and its
    # result returned.
    #
    # @overload fetch(key)
    #   A key
    #   @param [Object] key
    # @overload fetch(key, default)
    #   A key and a default value
    #   @param [Object] key
    #   @param [Object] default
    # @overload fetch(key) {|key| block }
    #   A key and a code block
    #   @param [Object]
    #   @yield [key] Passes the key to the block
    # @return [Object] the value for the key or the default
    def fetch(*args, &block)
      super(transform_key(args.shift), *args, &block)
    end

    # Delete a header
    def delete(key)
      super(transform_key(key))
    end

    # Select matching headers
    def grep(pattern)
      self.class[select { |k, _| pattern === k }]
    end

    private

    def transform_key(key)
      key.to_s.downcase
    end
  end # class Headers
end # module Webmachine
