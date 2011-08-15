require 'webmachine/translation'

module Webmachine
  module Decision
    # Contains methods concerned with Content Negotiation,
    # specifically, choosing media types, encodings, character sets
    # and languages.
    module Conneg
      HAS_ENCODING = defined?(::Encoding) # Ruby 1.9 compat

      # Given the 'Accept' header and provided types, chooses an
      # appropriate media type.
      # @api private
      def choose_media_type(provided, header)
        requested = MediaTypeList.build(header.split(/\s*,\s*/))
        provided = provided.map do |p| # normalize_provided
          MediaType.new(*Array(p))
        end
        # choose_media_type1
        chosen = nil
        requested.each do |_, requested_type|
          break if chosen = media_match(requested_type, provided)
        end
        chosen.to_s if chosen
      end

      # Given the 'Accept-Encoding' header and provided encodings, chooses an appropriate
      # encoding.
      # @api private
      def choose_encoding(provided, header)
        encodings = provided.map {|p| p.first }
        if encoding = do_choose(encodings, header, "identity")
          response.headers['Content-Encoding'] = encoding unless encoding == 'identity'
          metadata['Content-Encoding'] = encoding
        end
      end

      # Given the 'Accept-Charset' header and provided charsets,
      # chooses an appropriate charset.
      # @api private
      def choose_charset(provided, header)
        if provided && !provided.empty?
          charsets = provided.map {|c| c.first }
          if charset = do_choose(charsets, header, HAS_ENCODING ? Encoding.default_external.name : kcode_charset)
            metadata['Charset'] = charset
          end
        else
          true
        end
      end

      # Makes an conneg choice based what is accepted and what is
      # provided.
      # @api private
      def do_choose(choices, header, default)
        choices = choices.dup.map {|s| s.downcase }
        accepted = PriorityList.build(header.split(/\s*,\s/))
        default_priority = accepted.priority_of(default)
        star_priority = accepted.priority_of("*")
        default_ok = (default_priority.nil? && star_priority != 0.0) || default_priority
        any_ok = star_priority && star_priority > 0.0
        chosen = accepted.find do |priority, acceptable|
          if priority == 0.0
            choices.delete(acceptable.downcase)
            false
          else
            choices.include?(acceptable.downcase)
          end
        end
        (chosen && chosen.last) ||  # Use the matching one
          (any_ok && choices.first) || # Or first if "*"
          (default_ok && choices.include?(default) && default) # Or default
      end

      private

      # Encapsulates a MIME media type, with logic for matching types.
      class MediaType
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

        private
        def type_matches?(other)
          if ["*", "*/*", type].include?(other.type)
            true
          else
            other.major == major && other.minor == "*"
          end
        end
      end

      # Matches the requested media type (with potential modifiers)
      # against the provided types (with potential modifiers).
      # @param [MediaType] requested the requested media type
      # @param [Array<MediaType>] provided the provided media
      #     types
      # @return [MediaType] the first media type that matches
      def media_match(requested, provided)
        return provided.first if requested.matches_all?
        provided.find do |p|
          p.match?(requested)
        end
      end

      # Translate a KCODE value to a charset name
      def kcode_charset
        case $KCODE
        when /^U/i
          "UTF-8"
        when /^S/i
          "Shift-JIS"
        when /^B/i
          "Big5"
        else #when /^A/i, nil
          "ASCII"
        end
      end

      # @private
      # Content-negotiation priority list that takes into account both
      # assigned priority ("q" value) as well as order, since items
      # that come earlier in an acceptance list have higher priority
      # by fiat.
      class PriorityList
        # Given an acceptance list, create a PriorityList from them.
        def self.build(list)
          new.tap do |plist|
            list.each {|item| plist.add_header_val(item) }
          end
        end

        include Enumerable

        # Matches acceptable items that include 'q' values
        CONNEG_REGEX = /^\s*(\S+);\s*q=(\S*)\s*$/

        # Creates a {PriorityList}.
        # @see PriorityList::build
        def initialize
          @hash = Hash.new {|h,k| h[k] = [] }
          @index = {}
        end

        # Adds an acceptable item with the given priority to the list.
        # @param [Float] q the priority
        # @param [String] choice the acceptable item
        def add(q, choice)
          @index[choice] = q
          @hash[q] << choice
        end

        # Given a raw acceptable value from an acceptance header,
        # parse and add it to the list.
        # @param [String] c the raw acceptable item
        # @see #add
        def add_header_val(c)
          if c =~ CONNEG_REGEX
            choice, q = $1, $2
            q = "0" << q if q =~ /^\./ # handle strange FeedBurner Accept
            add(q.to_f,choice)
          else
            add(1.0, c)
          end
        end

        # @param [Float] q the priority to lookup
        # @return [Array<String>] the list of acceptable items at
        #     the given priority
        def [](q)
          @hash[q]
        end

        # @param [String] choice the acceptable item
        # @return [Float] the priority of that value
        def priority_of(choice)
          @index[choice]
        end

        # Iterates over the list in priority order, that is, taking
        # into account the order in which items were added as well as
        # their priorities.
        # @yield [q,v]
        # @yieldparam [Float] q the acceptable item's priority
        # @yieldparam [String] v the acceptable item
        def each
          @hash.to_a.sort.reverse_each do |q,l|
            l.each {|v| yield q, v }
          end
        end
      end

      # Like a {PriorityList}, but for {MediaTypes}, since they have
      # parameters in addition to q.
      # @private
      class MediaTypeList < PriorityList
        include Translation

        MEDIA_TYPE_REGEX = /^\s*([^;]+)((?:;\S+\s*)*)\s*$/
        PARAMS_REGEX = /;([^=]+)=([^;=\s]+)/

        # Overrides {PriorityList#add_header_val} to insert
        # {MediaType} items instead of Strings.
        # @see PriorityList#add_header_val
        def add_header_val(c)
          if c =~ MEDIA_TYPE_REGEX
            type, raw_params = $1, $2
            params = Hash[raw_params.scan(PARAMS_REGEX)]
            q = params.delete('q') || 1.0
            add(q.to_f, MediaType.new(type, params))
          else
            raise MalformedRequest, t('invalid_media_type', :type => c)
          end
        end
      end
    end
  end
end
