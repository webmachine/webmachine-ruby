
module Webmachine
  class Cookie

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
    
    ALLOWED_ATTRIBUTES = [:secure, :httponly, :path, :domain,
                          :comment, :maxage, :expires, :version]

    def http_only?
      @attributes[:httponly]
    end

    def secure?
      @attributes[:secure]
    end

    def path
      @attributes[:path]
    end

    def domain
      @attributes[:domain]
    end

    def comment
      @attributes[:comment]
    end

    def version
      @attributes[:version]
    end

    def maxage
      @attributes[:maxage]
    end

    def expires
      @attributes[:expires]
    end

    def initialize(name, value, attributes = {})
      @name, @value, @attributes = name, value, attributes
    end

    def to_s
      attributes = ALLOWED_ATTRIBUTES.select { |a| @attributes[a] }.map { |a|
        case a
        when :httponly
          "HttpOnly" if @attributes[a]
        when :secure
          "Secure" if @attributes[a]
        when :maxage
          "MaxAge=" + @attributes[a].to_s
        when :expires
          "Expires=" + rfc2822(@attributes[a])
        when :comment
          "Comment=" + escape(@attributes[a].to_s)
        else
          a.to_s.sub(/^\w/) { $&.capitalize } + "="  + @attributes[a].to_s
        end
      }.select { |attr| attr }

      ([escape(name) + "=" + escape(value)] + attributes).join("; ")
    end

    private

    def rfc2822(time)
      wday = Time::RFC2822_DAY_NAME[time.wday]
      mon = Time::RFC2822_MONTH_NAME[time.mon - 1]
      time.strftime("#{wday}, %d-#{mon}-%Y %H:%M:%S GMT")
    end

    def escape(s)
      URI.encode_www_form_component(s)
    end

    if defined?(::Encoding)
      def self.unescape(s, encoding = Encoding::UTF_8)
        URI.decode_www_form_component(s, encoding)
      end
    else
      def self.unescape(s, encoding = nil)
        URI.decode_www_form_component(s, encoding)
      end
    end
  end
end
