module Webmachine
  # A Weak Entity Tag, which can be used to compare entities which are
  # semantically equivalent, but do not have the same byte-content.
  class WeakETag
    # The pattern for a 'quoted-string' type
    QUOTED_STRING = /^"((?:\\"|[^"])*)"$/.freeze

    # The pattern for a weak entity tag
    WEAK_ETAG = /^W\/"((?:\\"|[^"])*)"$/.freeze
    
    attr_reader :etag
    
    def initialize(etag)
      @etag = quote(etag)
    end

    # A WeakETag is equivalent to an entity tag if the non-weak
    # portions are equivalent. It is also equivalent to a String which
    # represents the equivalent strong or weak ETag.
    def ==(other)
      case other
      when self.class
        other.etag == @etag
      when String
        quote(other) == @etag
      end
    end

    def to_s
      "W/#{quote @etag}"
    end
    
    private
    def unquote(str)
      if str =~ QUOTED_STRING
        $1
      elsif str =~ WEAK_ETAG
        $1
      else
        str
      end
    end

    def quote(str)
      if str =~ QUOTED_STRING
        str
      elsif str =~ WEAK_ETAG
        quote($1)
      else
        %Q{"#{escape_quotes str}"}
      end
    end

    def escape_quotes(str)
      str.gsub(/"/, '\\"')
    end
  end
end
