module Webmachine
  # Case-insensitive Hash of Request headers
  class Headers < ::Hash
    def [](key)
      super transform_key(key)
    end

    def []=(key,value)
      super transform_key(key), value
    end

    def delete(key)
      super transform_key(key)
    end
    
    def grep(pattern)
      self.class[select { |k,_| pattern === k }]
    end

    private
    def transform_key(key)
      key.to_s.downcase
    end
  end
end
