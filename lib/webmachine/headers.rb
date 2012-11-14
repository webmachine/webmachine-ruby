module Webmachine
  # Case-insensitive Hash of Request headers
  class Headers < ::Hash
    # Convert CGI-style Hash into Request headers
    # @param [Hash] env a hash of CGI-style env/headers
    # @return [Webmachine::Headers]
    def self.from_cgi(env)
      env.inject(new) do |h,(k,v)|
        if k =~ /^HTTP_(\w+)$/ || k =~ /^(CONTENT_(?:TYPE|LENGTH))$/
          h[$1.tr("_", "-")] = v
        end
        h
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
      super(super(*args).map {|k, v| [k.to_s.downcase, v]})
    end

    # Fetch a header
    def [](key)
      super transform_key(key)
    end

    # Set a header
    def []=(key,value)
      super transform_key(key), value
    end

    # Delete a header
    def delete(key)
      super transform_key(key)
    end

    # Select matching headers
    def grep(pattern)
      self.class[select { |k,_| pattern === k }]
    end

    private
    def transform_key(key)
      key.to_s.downcase
    end
  end # class Headers
end # module Webmachine
