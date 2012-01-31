module Webmachine
  # Case-insensitive Hash of Request headers
  class Headers < ::Hash
    # Convert CGI-style Hash into Request headers
    # @param [Hash] env a hash of CGI-style env/headers
    def self.from_cgi(env)
      env.inject(new) do |h,(k,v)|
        if k =~ /^HTTP_(\w+)$/ || k =~ /^(CONTENT_TYPE)$/
          h[$1.tr("_", "-")] = v
        end
        h
      end
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
