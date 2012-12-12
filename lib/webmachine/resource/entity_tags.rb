require 'webmachine/etags'

module Webmachine
  class Resource
    module EntityTags
      # Marks a generated entity tag (etag) as "weak", meaning that
      # other representations of the resource may be semantically equivalent.
      # @return [WeakETag] a weak version of the given ETag string
      # @param [String] str the ETag to mark as weak
      # @see http://tools.ietf.org/html/rfc2616#section-13.3.3
      # @see http://tools.ietf.org/html/rfc2616#section-14.19
      def weak_etag(str)
        WeakETag.new(str)
      end
    end
  end
end
