require 'webmachine/translation'
require 'webmachine/media_type'

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
          MediaType.parse(p)
        end
        # choose_media_type1
        chosen = nil
        requested.each do |_, requested_type|
          break if chosen = media_match(requested_type, provided)
        end
        chosen
      end

      # Given the 'Accept-Encoding' header and provided encodings, chooses an appropriate
      # encoding.
      # @api private
      def choose_encoding(provided, header)
        encodings = provided.keys
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

      # Given the 'Accept-Language' header and provided languages,
      # chooses an appropriate language.
      # @api private
      def choose_language(provided, header)
        if provided && !provided.empty?
          requested = PriorityList.build(header.split(/\s*,\s*/))
          star_priority = requested.priority_of("*")
          any_ok = star_priority && star_priority > 0.0
          accepted = requested.find do |priority, range|
            if priority == 0.0
              provided.delete_if {|tag| language_match(range, tag) }
              false
            else
              provided.any? {|tag| language_match(range, tag) }
            end
          end
          chosen = if accepted
                     provided.find {|tag| language_match(accepted.last, tag) }
                   elsif any_ok
                     provided.first
                   end
          if chosen
            metadata['Language'] = chosen
            response.headers['Content-Language'] = chosen
          end
        else
          true
        end
      end

      # Implements language-negotation matching as described in
      # RFC2616, section 14.14.
      #
      # A language-range matches a language-tag if it exactly
      # equals the tag, or if it exactly equals a prefix of the
      # tag such that the first tag character following the prefix
      # is "-".
      def language_match(range, tag)
        range.downcase == tag.downcase || tag =~ /^#{Regexp.escape(range)}\-/i
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
      # Matches acceptable items that include 'q' values
      CONNEG_REGEX = /^\s*(\S+);\s*q=(\S*)\s*$/

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

      # Like a {PriorityList}, but for {MediaType}s, since they have
      # parameters in addition to q.
      # @private
      class MediaTypeList < PriorityList
        include Translation

        # Overrides {PriorityList#add_header_val} to insert
        # {MediaType} items instead of Strings.
        # @see PriorityList#add_header_val
        def add_header_val(c)
          begin
            mt = MediaType.parse(c)
            q = mt.params.delete('q') || 1.0
            add(q.to_f, mt)
          rescue ArgumentError
            raise MalformedRequest, t('invalid_media_type', :type => c)
          end
        end
      end
    end
  end
end
