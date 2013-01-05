require 'webmachine/streaming'
require 'webmachine/media_type'
require 'webmachine/quoted_string'
require 'webmachine/etags'

module Webmachine
  module Decision
    # Methods that assist the Decision {Flow}.
    module Helpers
      include QuotedString

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
                        when String # 1.8 treats Strings as Enumerable
                          resource.send(encoder, resource.send(charsetter, body))
                        when Fiber
                          FiberEncoder.new(resource, encoder, charsetter, body)
                        when Enumerable
                          EnumerableEncoder.new(resource, encoder, charsetter, body)
                        else
                          if body.respond_to?(:call)
                            CallableEncoder.new(resource, encoder, charsetter, body)
                          else
                            resource.send(encoder, resource.send(charsetter, body))
                          end
                        end
        if String === response.body
          set_content_length
        else
          response.headers.delete 'Content-Length'
          response.headers['Transfer-Encoding'] = 'chunked'
        end
      end

      # Assists in receiving request bodies
      def accept_helper
        content_type = MediaType.parse(request.content_type || 'application/octet-stream')
        acceptable = resource.content_types_accepted.find {|ct, _| content_type.match?(ct) }
        if acceptable
          resource.send(acceptable.last)
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

      # Adds caching-related headers to the response.
      def add_caching_headers
        if etag = resource.etag
          response.headers['ETag'] = ETag.new(etag).to_s
        end
        if expires = resource.expires
          response.headers['Expires'] = expires.httpdate
        end
        if modified = resource.last_modified
          response.headers['Last-Modified'] = modified.httpdate
        end
      end

      # Ensures that responses have an appropriate Content-Length
      # header
      def ensure_content_length
        case
        when response.headers['Transfer-Encoding']
          return
        when [204, 205, 304].include?(response.code)
          response.headers.delete 'Content-Length'
        when has_response_body?
          set_content_length
        else
          response.headers['Content-Length'] = '0'
        end
      end

      # Sets the Content-Length header on the response
      def set_content_length
        if response.body.respond_to?(:bytesize)
          response.headers['Content-Length'] = response.body.bytesize.to_s
        else
          response.headers['Content-Length'] = response.body.length.to_s
        end
      end
    end # module Helpers
  end # module Decision
end # module Webmachine
