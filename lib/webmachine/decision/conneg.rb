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
        requested = header.split(/\s*,\s*/).inject(MediaTypeList.new) do |acc, v|
          acc.add_header_val(v)
          acc
        end
        provided = provided.map do |p| # normalize_provided
          case p
          when String
            [p, {}]
          when Array
            p
          end
        end
        # choose_media_type1
        chosen = nil
        requested.each do |_, type_and_params|
          break if chosen = media_match(type_and_params, provided)             
        end
        format_content_type(*chosen) if chosen
      end

      # Given the 'Accept-Encoding' header and provided encodings, chooses an appropriate
      # encoding.
      # @api private
      def choose_encoding(provided, header)
        encodings = provided.map {|p| p.first }
        if encoding = do_choose(encodings, header, "identity")
          response.header['Content-Encoding'] = encoding unless encoding == 'identity'
          metadata['Content-Encoding'] = encoding
        end
      end

      # Given the 'Accept-Charset' header and provided charsets,
      # chooses an appropriate charset.
      # @api private
      def choose_charset(provided, header)
        if provided && provided.any?
          charsets = provided.map {|c| c.first }
          if charset = do_choose(charsets, header, HAS_ENCODING ? Encoding.default_external.name : kcode_charset)
            metadata['Charset'] = charset
          end
        end
      end

      # Makes an conneg choice based what is accepted and what is provided.
      def do_choose(choices, header, default)
        choices = choices.dup.map {|s| s.downcase }
        accepted = build_conneg_list(header.split(/\s*,\s/))
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

      # Given the choices in a conneg header, order them by appearance
      # but also accounting for priority given by the client in the
      # 'q' parameter.
      def build_conneg_list(choices)
        choices.inject(PriorityList.new) do |acc, c|
          acc.add_header_val(c)
          acc
        end
      end

      private
      def format_content_type(type, params)
        [type, *params.map {|k,v| "#{k}=#{v}" }].join(";")
      end
      
      def media_match(requested, provided)
        rtype, rparams = requested
        return provided.first if rtype == "*/*" && rparams.empty?
        provided.find do |type_and_params|
          type, params = type_and_params
          media_type_match(type, rtype) && params == rparams # media_params_match
        end
      end

      def media_type_match(requested, provided)
        if ["*", "*/*", provided].include?(requested)
          true
        else
          r1, r2 = requested.split('/')
          p1, _ = provided.split('/')
          r2 == "*" && r1 == p1
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
      class PriorityList
        include Enumerable
        # This needs to consider order as well as priority since an item
        # that comes earlier in the header has higher priority by
        # fiat, so we can't just sort by priority. We have to group by
        # priority, in order, then sort the groups by priority, and
        # finally concatenate.

        CONNEG_REGEX = /^\s*(\S+);\s*q=(\S*)\s*$/

        def initialize
          @hash = Hash.new {|h,k| h[k] = [] }
          @index = {}
        end

        def add(q, choice)
          @index[choice] = q
          @hash[q] << choice
        end

        def add_header_val(c)
          if c =~ CONNEG_REGEX
            choice, q = $1, $2
            q = "0" << q if q =~ /^\./ # handle strange FeedBurner Accept
            add(q.to_f,choice)
          else
            add(1.0, c)
          end
        end

        def [](q)
          @hash[q]
        end

        def priority_of(choice)
          @index[choice]
        end

        def each
          @hash.to_a.sort.reverse_each do |q,l|
            l.each {|v| yield q, v }
          end
        end
      end

      # @private
      # Media types have parameters in addition to q, so we have to
      # take those into account.
      class MediaTypeList < PriorityList
        MEDIA_TYPE_REGEX = /^\s*([^;]+)((?:;\S+\s*)*)\s*$/
        PARAMS_REGEX = /;([^=]+)=([^;=\s]+)/
        def add_header_val(c)
          if c =~ MEDIA_TYPE_REGEX
            type, raw_params = $1, $2
            params = Hash(raw_params.scan(PARAMS_REGEX))
            q = params.delete('q') || 1.0
            params.empty? ? add(q.to_f, type) : add(q.to_f, [type, params])
          else
            # Silently ignore bad media types?
            # raise MalformedRequest, "invalid media type specified in Accept header: #{c}"
          end
        end
      end
    end
  end
end
