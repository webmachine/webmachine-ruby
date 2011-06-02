module Webmachine
  # Case-insensitive Hash of request headers
  class Headers < ::Hash
    def [](key)
      super key.to_s.downcase
    end

    def []=(key,value)
      super key.to_s.downcase, value
    end
  end
end
