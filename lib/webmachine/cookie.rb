require 'uri'

module Webmachine
  # An HTTP Cookie for a response, including optional attributes
  class Cookie
    # Parse a Cookie header, with any number of cookies, into a hash
    # @param [String] the Cookie header
    # @param [Boolean] whether to include duplicate cookie values in the
    #    response
    # @return [Hash] cookie name/value pairs.
    def self.parse(cstr, include_dups = false)
      cookies = {}
      (cstr || '').split(/\s*[;,]\s*/n).each { |c|
        k,v = c.split(/\s*=\s*/, 2).map { |s| unescape(s) }

        case cookies[k]
        when nil
          cookies[k] = v
        when Array
          cookies[k] << v
        else
          cookies[k] = [cookies[k], v] if include_dups
        end
      }

      cookies
    end

    attr_reader :name, :value

    # Allowed keys for the attributes parameter of
    # {Webmachine::Cookie#initialize}
    ALLOWED_ATTRIBUTES = [:secure, :httponly, :path, :domain,
                          :comment, :maxage, :expires, :version]

    # If the cookie is HTTP only
    def http_only?
      @attributes[:httponly]
    end

    # If the cookie should be treated as a secure one by the client
    def secure?
      @attributes[:secure]
    end

    # The path for which the cookie is valid
    def path
      @attributes[:path]
    end

    # The domain for which the cookie is valid
    def domain
      @attributes[:domain]
    end

    # A comment allowing documentation on the intended use for the cookie
    def comment
      @attributes[:comment]
    end

    # Which version of the state management specification the cookie conforms
    def version
      @attributes[:version]
    end

    # The Max-Age, in seconds, for which the cookie is valid
    def maxage
      @attributes[:maxage]
    end

    # The expiration {DateTime} of the cookie
    def expires
      @attributes[:expires]
    end

    def initialize(name, value, attributes = {})
      @name, @value, @attributes = name, value, attributes
    end

    # Convert to an RFC2109 valid cookie string
    # @return [String] The RFC2109 valid cookie string
    def to_s
      attributes = ALLOWED_ATTRIBUTES.select { |a| @attributes[a] }.map do |a|
        case a
        when :httponly
          "HttpOnly" if @attributes[a]
        when :secure
          "Secure" if @attributes[a]
        when :maxage
          "Max-Age=" + @attributes[a].to_s
        when :expires
          "Expires=" + rfc2822(@attributes[a])
        when :comment
          "Comment=" + escape(@attributes[a].to_s)
        else
          a.to_s.sub(/^\w/) { $&.capitalize } + "="  + @attributes[a].to_s
        end
      end

      ([escape(name) + "=" + escape(value)] + attributes).join("; ")
    end

    private

    def rfc2822(time)
      wday = Time::RFC2822_DAY_NAME[time.wday]
      mon = Time::RFC2822_MONTH_NAME[time.mon - 1]
      time.strftime("#{wday}, %d-#{mon}-%Y %H:%M:%S GMT")
    end

    if URI.respond_to?(:decode_www_form_component) and defined?(::Encoding)
      # Escape a cookie
      def escape(s)
        URI.encode_www_form_component(s)
      end

      # Unescape a cookie
      # @private
      def self.unescape(s, encoding = Encoding::UTF_8)
        URI.decode_www_form_component(s, encoding)
      end
    else # We're on 1.8.7, or JRuby or Rubinius in 1.8 mode
      # Copied and modified from 1.9.x URI
      # @private
      TBLENCWWWCOMP_ = {}
      256.times do |i|
        TBLENCWWWCOMP_[i.chr] = '%%%02X' % i
      end
      TBLENCWWWCOMP_[' '] = '+'
      TBLENCWWWCOMP_.freeze

      # @private
      TBLDECWWWCOMP_ = {}
      256.times do |i|
        h, l = i>>4, i&15
        TBLDECWWWCOMP_['%%%X%X' % [h, l]] = i.chr
        TBLDECWWWCOMP_['%%%x%X' % [h, l]] = i.chr
        TBLDECWWWCOMP_['%%%X%x' % [h, l]] = i.chr
        TBLDECWWWCOMP_['%%%x%x' % [h, l]] = i.chr
      end
      TBLDECWWWCOMP_['+'] = ' '
      TBLDECWWWCOMP_.freeze

      # Decode given +str+ of URL-encoded form data.
      #
      # This decodes + to SP.
      #
      # @private
      def self.unescape(str, enc=nil)
        raise ArgumentError, "invalid %-encoding (#{str})" unless /\A(?:%\h\h|[^%]+)*\z/ =~ str
        str.gsub(/\+|%\h\h/){|c| TBLDECWWWCOMP_[c] }
      end

      # Encode given +str+ to URL-encoded form data.
      #
      # This method doesn't convert *, -, ., 0-9, A-Z, _, a-z, but does convert SP
      # (ASCII space) to + and converts others to %XX.
      #
      # This is an implementation of
      # http://www.w3.org/TR/html5/forms.html#url-encoded-form-data
      #
      # @private
      def escape(str)
        str.to_s.gsub(/[^*\-.0-9A-Z_a-z]/){|c| TBLENCWWWCOMP_[c] }
      end
    end
  end
end
