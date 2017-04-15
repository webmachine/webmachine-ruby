require 'strscan'

module Webmachine
  # Represents the value of a Cache-Control header. Suitable for use either for
  # building a header to return in a Response or for parsing a client Request
  #
  # There is some limited validation of the directives given - boolean
  # directives are constrained, and unrecognized ones are rejected.
  #
  # The available directives are as follows:
  #
  # Per http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.9
  # Cache-Control   = "Cache-Control" ":" 1#cache-directive"
  #    cache-request-directive =
  #       "no-cache"
  #     | "no-store"
  #     | "max-age" "=" delta-seconds
  #     | "max-stale" [ "=" delta-seconds ]
  #     | "min-fresh" "=" delta-seconds
  #     | "no-transform"
  #     | "only-if-cached"
  #     | cache-extension
  #
  # cache-response-directive =
  #       "public"
  #     | "private" [ "=" <"> 1#field-name <"> ]
  #     | "no-cache" [ "=" <"> 1#field-name <"> ]
  #     | "no-store"
  #     | "no-transform"
  #     | "must-revalidate"
  #     | "proxy-revalidate"
  #     | "max-age" "=" delta-seconds
  #     | "s-maxage" "=" delta-seconds
  #     | cache-extension
  # cache-extension = token [ "=" ( token | quoted-string ) ]"
  #
  # When using hash keys, use a symbol, replacing '-' with '_'. For example:
  # "no-store" becomes { :no_store => true }

  class CacheControl
    # @private
    BOOLEAN_DIRECTIVES = {
      :no_store => "no-store",
      :no_transform => "no-transform",
      :only_if_cached => "only-if-cached",
      :public => "public",
      :no_store => "no-store",
      :no_transform => "no-transform",
      :must_revalidate => "must-revalidate",
      :proxy_revalidate => "proxy-revalidate"
    }

    # @private
    VALUED_DIRECTIVES = {
      :max_age => "max-age",
      :max_stale => "max-stale",
      :min_fresh => "min-fresh",
      :private => "private",
      :no_cache => "no-cache",
      :s_maxage => "s-maxage"
    }

    # @private
    ALL_DIRECTIVES = BOOLEAN_DIRECTIVES.merge(VALUED_DIRECTIVES)

    # @private
    DIRECTIVE_SYMBOLS = Hash[ALL_DIRECTIVES.map{|value, name| [name, value]}]

    # @private
    QUOTED_STRING = /(['"])((?:(?!=\1).)*)\1/

    class << self
      # Parse the value of a Cache-Control header into a CacheControl object
      # @param [String] string The string-format header value
      # @param [Array|nil] expected_extension_tokens Any tokens expected in a
      #   Cache Control header
      # @return [CacheControl]
      def parse(string, expected_extension_tokens = nil)
        ext_tokens = Hash[(expected_extension_tokens || []).map{|tok| [tok.to_s, true]}]
        directives = {}
        scanner = StringScanner.new(string)
        strings = [""]
        quotes = []

        until scanner.eos?
          chunk = scanner.scan(/[^,"']*/)
          break if chunk.nil?
          strings.last << chunk.sub(/\s*\Z/,'')
          char = scanner.scan(/[,"']/)

          if char == ","
            if quotes.empty?
              strings << ""
            else
              strings.last << char
            end
          else
            strings.last << char
            if quotes.last == char
              quotes.pop
            else
              quotes.push char
            end
          end
          scanner.scan(/\s*/)
        end
        strings.last << scanner.rest

        strings.each do |string|
          next if string.empty?
          name, value = string.split(/\s*=\s*/, 2)
          name.downcase!
          if value.nil?
            directives[DIRECTIVE_SYMBOLS[name]] = true
          elsif DIRECTIVE_SYMBOLS.has_key?(name)
            begin
              directives[DIRECTIVE_SYMBOLS[name]] = Integer(value)
            rescue ArgumentError
              if (match = QUOTED_STRING.match value).nil?
                directives[DIRECTIVE_SYMBOLS[name]] = value
              else
                items = match[2].split(/\s*,\s*/)
                directives[DIRECTIVE_SYMBOLS[name]] = items
              end
            end
          else
            directives[:extensions] ||= {}
            parsed_value =
              if (match = QUOTED_STRING.match value).nil?
                if ext_tokens.has_key?(value)
                  value.intern
                else
                  value
                end
              else
                match[2]
              end
            directives[:extensions].merge!( name => parsed_value )
          end
        end
        return from_hash(directives)
      end
      alias from_string parse

      def from_hash(hash)
        instance = self.new
        instance.update_from_hash(hash)
        return instance
      end
    end

    # @param [Hash] directives a hash of the header directives
    #
    # Create a CacheControl object based on a hash of directives to encode in
    # the header. Boolean directives (e.g. no-cache) should be
    # specified with the value 'true' (which can be a little confusing).
    #
    # Cache-Control extensions should go into a sub-hash as the value of an
    # :extensions key
    #
    # @example
    #   CacheControl.new(
    #     :max_age => 3600,
    #     :extensions => {:community => "basho"}
    #   )
    def initialize(hash=nil)
      @directives = {}
      unless hash.nil?
        update_from_hash(hash)
      end
    end

    # Preferred method of accessing directives
    def [](name)
      name = DIRECTIVE_SYMBOLS.fetch(name, name)
      @directives[name]
    end

    # Set directives by name. Use "true" for boolean directives like no-store
    #
    # @param [String|Symbol] name
    # @param [String|true|Array] value
    def []=(name, value)
      name = DIRECTIVE_SYMBOLS.fetch(name, name)
      if BOOLEAN_DIRECTIVES.has_key?(name) and value != true
        raise ArgumentError, "Invalid Cache Control directive value: #{name.inspect} can only be 'true' not #{value.inspect}"
      end
      if not (ALL_DIRECTIVES.has_key?(name) or
              [:cache_extension, :extension, :extensions, :cache_extensions].include?(name))
              raise ArgumentError, "Invalid CacheControl directive: unrecognized directive #{name.inspect}"
      end
      @directives[name] = value
    end

    # Bulk update of directive values - each key will set a directive
    def update_from_hash(hash)
      hash.each_pair do |name, value|
        self[name] = value
      end
    end

    # Accessor for directive
    def no_cache
      @directives[:no_cache]
    end

    # Accessor for directive
    def no_store
      @directives[:no_store]
    end

    # Accessor for directive
    def max_age
      @directives[:max_age]
    end

    # Accessor for directive
    def max_stale
      @directives[:max_stale]
    end

    # Accessor for directive
    def min_fresh
      @directives[:min_fresh]
    end

    # Accessor for directive
    def no_transform
      @directives[:no_transform]
    end

    # Accessor for directive
    def only_if_cached
      @directives[:only_if_cached]
    end

    # Accessor for directive
    def public
      @directives[:public]
    end

    # Accessor for directive
    def private
      @directives[:private]
    end

    # Accessor for directive
    def no_cache
      @directives[:no_cache]
    end

    # Accessor for directive
    def no_store
      @directives[:no_store]
    end

    # Accessor for directive
    def no_transform
      @directives[:no_transform]
    end

    # Accessor for directive
    def must_revalidate
      @directives[:must_revalidate]
    end

    # Accessor for directive
    def proxy_revalidate
      @directives[:proxy_revalidate]
    end

    # Accessor for directive
    def max_age
      @directives[:max_age]
    end

    # Accessor for directive
    def s_maxage
      @directives[:s_maxage]
    end

    # Accessor for extensions hash
    def extensions
      @directives[:extensions]
    end
    alias cache_extensions extensions

    # Render the header value represented by the object
    def to_s
      directive_strings = @directives.map do |name, value|
        case name
        when *BOOLEAN_DIRECTIVES.keys
          BOOLEAN_DIRECTIVES[name]
        when :max_age
          "max-age=#{value.to_i}"
        when :min_fresh
          "min-fresh=#{value.to_i}"
        when :s_maxage
          "s-maxage=#{value.to_i}"
        when :max_stale
          if value == true
            "max-stale"
          else
            "max-stale=#{value.to_i}"
          end
        when :private
          if value == true
            "private"
          else
            "private=\"#{value.join(", ")}\""
          end
        when :no_cache
          if value == true
            "no-cache"
          else
            "no-cache=\"#{value.join(", ")}\""
          end
        when :extension, :cache_extension, :extensions
          value.map do |name, value|
            if value.is_a? Symbol
              "#{name}=#{value}"
            else
              "#{name}=\"#{value}\""
            end
          end.join(", ")
        end
      end
      directive_strings.join(", ")
    end
  end
end
