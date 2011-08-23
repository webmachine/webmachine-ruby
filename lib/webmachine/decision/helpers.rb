require 'webmachine/streaming'
module Webmachine
  module Decision
    # Methods that assist the Decision {Flow}.
    module Helpers
      QUOTED = /^"(.*)"$/

      # Determines if the response has a body/entity set.
      def has_response_body?
        !response.body.nil? && !response.body.empty?
      end

      # If the response body exists, encode it.
      # @see #encode_body
      def encode_body_if_set
        encode_body if has_response_body?
      end

      # Encodes the body in the selected charset and encoding.
      def encode_body
        body = response.body
        chosen_charset = metadata['Charset']
        chosen_encoding = metadata['Content-Encoding']
        charsetter = resource.charsets_provided && resource.charsets_provided.find {|c,_| c == chosen_charset }.last || :charset_nop
        encoder = resource.encodings_provided[chosen_encoding]
        response.body = case body
                        when Enumerable
                          EnumerableEncoder.new(resource, encoder, charsetter, body)
                        when body.respond_to?(:call)
                          CallableEncoder.new(resource, encoder, charsetter, body)
                        else
                          resource.send(encoder, resource.send(charsetter, body))
                        end
      end

      # Ensures that a header is quoted (like ETag)
      def ensure_quoted_header(value)
        if value =~ QUOTED
          value
        else
          '"' << value << '"'
        end
      end

      # Unquotes request headers (like ETag)
      def unquote_header(value)
        if value =~ QUOTED
          $1
        else
          value
        end
      end

      # Assists in receiving request bodies
      def accept_helper
        content_type = request.content_type || 'application/octet-stream'
        mt = Conneg::MediaType.parse(content_type)
        metadata['mediaparams'] = mt.params
        acceptable = resource.content_types_accepted.find {|ct, _| mt.type_matches?(Conneg::MediaType.parse(ct)) }
        if acceptable
          resource.send(acceptor.last)
        else
          415
        end
      end

      # Computes the entries for the 'Vary' response header
      def variances
        resource.variances.tap do |v|
          v.unshift "Accept-Language" if resource.languages_provided.size > 1
          v.unshift "Accept-Charset" if resource.charsets_provided && resource.charsets_provided.size > 1
          v.unshift "Accept-Encoding" if resource.encodings_provided.size > 1
          v.unshift "Accept" if resource.content_types_provided.size > 1
        end
      end
    end
  end
end
