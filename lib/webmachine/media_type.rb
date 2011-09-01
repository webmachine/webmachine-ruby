module Webmachine
  # Encapsulates a MIME media type, with logic for matching types.
  class MediaType
    # Matches valid media types
    MEDIA_TYPE_REGEX = /^\s*([^;\s]+)\s*((?:;\S+\s*)*)\s*$/

    # Matches sub-type parameters
    PARAMS_REGEX = /;([^=]+)=([^;=\s]+)/

    # Creates a new MediaType by parsing its string representation.
    def self.parse(obj)
      case obj
      when MediaType
        obj
      when Array
        unless String == obj[0] && Hash === obj[1]
          raise ArgumentError, t('invalid_media_type', :type => obj.inspect)
        end
        type = parse(obj)
        type.params.merge! obj[1]
        type
      when MEDIA_TYPE_REGEX
        type, raw_params = $1, $2
        params = Hash[raw_params.scan(PARAMS_REGEX)]
        new(type, params)
      end
    end

    # @return [String] the MIME media type
    attr_accessor :type

    # @return [Hash] any type parameters, e.g. charset
    attr_accessor :params

    def initialize(type, params={})
      @type, @params = type, params
    end

    # Detects whether the {MediaType} represents an open wildcard
    # type, that is, "*/*" without any {#params}.
    def matches_all?
      @type == "*/*" && @params.empty?
    end

    def ==(other)
      other = self.class.parse(other) if String === other
      other.type == type && other.params == params
    end

    # Detects whether this {MediaType} matches the other {MediaType},
    # taking into account wildcards.
    def match?(other)
      type_matches?(other) && other.params == params
    end

    # Reconstitutes the type into a String
    def to_s
      [type, *params.map {|k,v| "#{k}=#{v}" }].join(";")
    end

    # @return [String] The major type, e.g. "application", "text", "image"
    def major
      type.split("/").first
    end

    # @return [String] the minor or sub-type, e.g. "json", "html", "jpeg"
    def minor
      type.split("/").last
    end

    def type_matches?(other)
      if ["*", "*/*", type].include?(other.type)
        true
      else
        other.major == major && other.minor == "*"
      end
    end
  end
end
