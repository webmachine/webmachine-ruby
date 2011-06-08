module Webmachine
  module Decision
    # Methods that assist the Decision {Flow}.
    module Helpers      
      QUOTED = /^"(.*)"$/

      # TODO
      def has_response_body?
      end
      
      # TODO
      def encode_body_if_set
        
      end

      # TODO
      def encode_body
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
      
      def accept_helper
        content_type = request.content_type || 'application/octet-stream'
        type, params = media_type_to_detail(content_type)
        metadata['mediaparams'] = params
        acceptable = resource.content_types_accepted.select {|ct, _| ct == content_type }
        if acceptable.any?
          _, acceptor = acceptable.first
          resource.send(acceptor)
        else
          415
        end          
      end

      # Computes the entries for the 'Vary' response header
      def variances
        resource.variances.tap do |v|
          v.unshift "Accept-Charset" if resource.charsets_provided && resource.charsets_provided.size > 1
          v.unshift "Accept-Encoding" if resource.encodings_provided.size > 1
          v.unshift "Accept" if resource.content_types_provided.size > 1
        end
      end
    end
  end
end
