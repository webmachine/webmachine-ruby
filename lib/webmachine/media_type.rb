require 'webmachine/translation'

module Webmachine
  # Encapsulates a MIME media type, with logic for matching types.
  class MediaType
    extend Translation
    # Matches valid media types
    MEDIA_TYPE_REGEX = /^\s*([^;\s]+)\s*((?:;\s*\S+\s*)*)\s*$/

    # Matches sub-type parameters
    PARAMS_REGEX = /;\s*([^=]+)=([^;=\s]+)/

    # Creates a new MediaType by parsing an alternate representation.
    # @param [MediaType, String, Array<String,Hash>] obj the raw type
    #   to be parsed
    # @return [MediaType] the parsed media type
    # @raise [ArgumentError] when the type could not be parsed
    def self.parse(obj)
      case obj
      when MediaType
        obj
      when MEDIA_TYPE_REGEX
        type, raw_params = $1, $2
        params = Hash[raw_params.scan(PARAMS_REGEX)]
        new(type, params)
      else
        unless Array === obj && String === obj[0] && Hash === obj[1]
          raise ArgumentError, t('invalid_media_type', :type => obj.inspect)
        end
        type = parse(obj[0])
        type.params.merge!(obj[1])
        type
      end
    end

    # @return [String] the MIME media type
    attr_accessor :type

    # @return [Hash] any type parameters, e.g. charset
    attr_accessor :params

    # @param [String] type the main media type, e.g. application/json
    # @param [Hash] params the media type parameters
    def initialize(type, params={})
      @type, @params = type, params
    end

    # Detects whether the {MediaType} represents an open wildcard
    # type, that is, "*/*" without any {#params}.
    def matches_all?
      @type == "*/*" && @params.empty?
    end

    # @return [true,false] Are these two types strictly equal?
    # @param other the other media type.
    # @see MediaType.parse
    def ==(other)
      other = self.class.parse(other)
      other.type == type && other.params == params
    end

    # Detects whether this {MediaType} matches the other {MediaType},
    # taking into account wildcards. Sub-type parameters are treated
    # strictly.
    # @param [MediaType, String, Array<String,Hash>] other the other type 
    # @return [true,false] whether it is an acceptable match
    def exact_match?(other)
      other = self.class.parse(other)
      type_matches?(other) && other.params == params
    end

    # Detects whether the {MediaType} is an acceptable match for the
    # other {MediaType}, taking into account wildcards and satisfying
    # all requested parameters, but allowing this type to have extra
    # specificity.
    # @param [MediaType, String, Array<String,Hash>] other the other type 
    # @return [true,false] whether it is an acceptable match
    def match?(other)
      other = self.class.parse(other)
      type_matches?(other) && params_match?(other.params)
    end

    # Detects whether the passed sub-type parameters are all satisfied
    # by this {MediaType}. The receiver is allowed to have other
    # params than the ones specified, but all specified must be equal.
    # @param [Hash] params the requested params
    # @return [true,false] whether it is an acceptable match
    def params_match?(other)
      other.all? {|k,v| params[k] == v }
    end
    
    # Reconstitutes the type into a String
    # @return [String] the type as a String
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

    # @param [MediaType] other the other type
    # @return [true,false] whether the main media type is acceptable,
    #   ignoring params and taking into account wildcards
    def type_matches?(other)
      other = self.class.parse(other)
      if ["*", "*/*", type].include?(other.type)
        true
      else
        other.major == major && other.minor == "*"
      end
    end
  end
end
