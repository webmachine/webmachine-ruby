require 'webmachine/quoted_string'

module Webmachine
  # A wrapper around entity tags that encapsulates their semantics.
  # This class by itself represents a "strong" entity tag.
  class ETag
    include QuotedString
    # The pattern for a weak entity tag
    WEAK_ETAG = /^W\/#{QUOTED_STRING}$/.freeze

    def self.new(etag)
      return etag if ETag === etag
      klass = WEAK_ETAG.match?(etag) ? WeakETag : self
      klass.send(:allocate).tap do |obj|
        obj.send(:initialize, etag)
      end
    end

    attr_reader :etag

    def initialize(etag)
      @etag = quote(etag)
    end

    # An entity tag is equivalent to another entity tag if their
    # quoted values are equivalent. It is also equivalent to a String
    # which represents the equivalent ETag.
    def ==(other)
      case other
      when ETag
        other.etag == @etag
      when String
        quote(other) == @etag
      end
    end

    # Converts the entity tag into a string appropriate for use in a
    # header.
    def to_s
      quote @etag
    end
  end

  # A Weak Entity Tag, which can be used to compare entities which are
  # semantically equivalent, but do not have the same byte-content. A
  # WeakETag is equivalent to another entity tag if the non-weak
  # portions are equivalent. It is also equivalent to a String which
  # represents the equivalent strong or weak ETag.
  class WeakETag < ETag
    # Converts the WeakETag to a String for use in a header.
    def to_s
      "W/#{super}"
    end

    private

    def unquote(str)
      if str =~ WEAK_ETAG
        unescape_quotes $1
      else
        super
      end
    end

    def quote(str)
      str = unescape_quotes($1) if str =~ WEAK_ETAG
      super
    end
  end
end
