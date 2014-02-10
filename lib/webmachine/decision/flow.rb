require 'time'
require 'digest/md5'
require 'base64'
require 'webmachine/decision/conneg'
require 'webmachine/decision/falsey'
require 'webmachine/translation'
require 'webmachine/etags'

module Webmachine
  module Decision
    # This module encapsulates all of the decisions in Webmachine's
    # flow-chart. These invoke {Webmachine::Resource::Callbacks} methods to
    # determine the appropriate response code, headers, and body for
    # the response.
    #
    # This module is included into {FSM}, which drives the processing
    # of the chart.
    # @see https://raw.github.com/wiki/basho/webmachine/images/http-headers-status-v3.png
    module Flow
      include Base64

      # Version of the flow diagram
      VERSION = 3

      # The first state in flow diagram
      START = :b13

      # Separate content-negotiation logic from flow diagram.
      include Conneg

      # Extract error strings into locale files
      include Translation

      # Handles standard decisions where halting is allowed
      def decision_test(test, iftrue, iffalse)
        case test
        when Fixnum # Allows callbacks to "halt" with a given response code
          test
        when Falsey
          iffalse
        else
          iftrue
        end
      end

      # Service available?
      def b13
        decision_test(resource.service_available?, :b12, 503)
      end

      # Known method?
      def b12
        decision_test(resource.known_methods.include?(request.method), :b11, 501)
      end

      # URI too long?
      def b11
        decision_test(resource.uri_too_long?(request.uri), 414, :b10)
      end

      # Method allowed?
      def b10
        if resource.allowed_methods.include?(request.method)
          :b9
        else
          response.headers["Allow"] = resource.allowed_methods.join(", ")
          405
        end
      end

      # Content-MD5 present?
      def b9
        request.content_md5 ? :b9a : :b9b
      end

      # Content-MD5 valid?
      def b9a
        case valid = resource.validate_content_checksum
        when Fixnum
          valid
        when true
          :b9b
        when false
          response.body = "Content-MD5 header does not match request body."
          400
        else # not_validated
          if decode64(request.content_md5) == Digest::MD5.hexdigest(request.body)
            :b9b
          else
            response.body = "Content-MD5 header does not match request body."
            400
          end
        end
      end

      # Malformed?
      def b9b
        decision_test(resource.malformed_request?, 400, :b8)
      end

      # Authorized?
      def b8
        result = resource.is_authorized?(request.authorization)
        case result
        when true
          :b7
        when Fixnum
          result
        when String
          response.headers['WWW-Authenticate'] = result
          401
        else
          401
        end
      end

      # Forbidden?
      def b7
        decision_test(resource.forbidden?, 403, :b6)
      end

      # Okay Content-* Headers?
      def b6
        decision_test(resource.valid_content_headers?(request.headers.grep(/content-/)), :b5,  501)
      end

      # Known Content-Type?
      def b5
        decision_test(resource.known_content_type?(request.content_type), :b4, 415)
      end

      # Req Entity Too Large?
      def b4
        decision_test(resource.valid_entity_length?(request.content_length), :b3, 413)
      end

      # OPTIONS?
      def b3
        if request.options?
          response.headers.merge!(resource.options)
          200
        else
          :c3
        end
      end

      # Accept exists?
      def c3
        if !request.accept
          metadata['Content-Type'] = MediaType.parse(resource.content_types_provided.first.first)
          :d4
        else
          :c4
        end
      end

      # Acceptable media type available?
      def c4
        types = resource.content_types_provided.map {|pair| pair.first }
        chosen_type = choose_media_type(types, request.accept)
        if !chosen_type
          406
        else
          metadata['Content-Type'] = chosen_type
          :d4
        end
      end

      # Accept-Language exists?
      def d4
        if !request.accept_language
          if language = choose_language(resource.languages_provided, "*")
            resource.language_chosen(language)
            :e5
          else
            406
          end
        else
          :d5
        end
      end

      # Acceptable language available?
      def d5
        if language = choose_language(resource.languages_provided, request.accept_language)
          resource.language_chosen(language)
          :e5
        else
          406
        end
      end

      # Accept-Charset exists?
      def e5
        if !request.accept_charset
          choose_charset(resource.charsets_provided, "*") ? :f6 : 406
        else
          :e6
        end
      end

      # Acceptable Charset available?
      def e6
        choose_charset(resource.charsets_provided, request.accept_charset) ? :f6 : 406
      end

      # Accept-Encoding exists?
      # (also, set content-type header here, now that charset is chosen)
      def f6
        chosen_type = metadata['Content-Type']
        if chosen_charset = metadata['Charset']
          chosen_type.params['charset'] = chosen_charset
        end
        response.headers['Content-Type'] = chosen_type.to_s
        if !request.accept_encoding
          choose_encoding(resource.encodings_provided, "identity;q=1.0,*;q=0.5") ? :g7 : 406
        else
          :f7
        end
      end

      # Acceptable encoding available?
      def f7
        choose_encoding(resource.encodings_provided, request.accept_encoding) ? :g7 : 406
      end

      # Resource exists?
      def g7
        # This is the first place after all conneg, so set Vary here
        response.headers['Vary'] =  variances.join(", ") if variances.any?
        decision_test(resource.resource_exists?, :g8, :h7)
      end

      # If-Match exists?
      def g8
        request.if_match ? :g9 : :h10
      end

      # If-Match: * exists?
      def g9
        quote(request.if_match) == '"*"' ? :h10 : :g11
      end

      # ETag in If-Match
      def g11
        request_etags = request.if_match.split(/\s*,\s*/).map {|etag| ETag.new(etag) }
        request_etags.include?(ETag.new(resource.generate_etag)) ? :h10 : 412
      end

      # If-Match exists?
      def h7
        (request.if_match && unquote(request.if_match) == '*') ? 412 : :i7
      end

      # If-Unmodified-Since exists?
      def h10
        request.if_unmodified_since ? :h11 : :i12
      end

      # If-Unmodified-Since is valid date?
      def h11
        date = Time.httpdate(request.if_unmodified_since)
        metadata['If-Unmodified-Since'] = date
      rescue ArgumentError
        :i12
      else
        :h12
      end

      # Last-Modified > I-UM-S?
      def h12
        resource.last_modified > metadata['If-Unmodified-Since'] ? 412 : :i12
      end

      # Moved permanently? (apply PUT to different URI)
      def i4
        case uri = resource.moved_permanently?
        when String, URI
          response.headers["Location"] = uri.to_s
          301
        when Fixnum
          uri
        else
          :p3
        end
      end

      # PUT?
      def i7
        request.put? ? :i4 : :k7
      end

      # If-none-match exists?
      def i12
        request.if_none_match ? :i13 : :l13
      end

      # If-none-match: * exists?
      def i13
        quote(request.if_none_match) == '"*"' ? :j18 : :k13
      end

      # GET or HEAD?
      def j18
        (request.get? || request.head?) ? 304 : 412
      end

      # Moved permanently?
      def k5
        case uri = resource.moved_permanently?
        when String, URI
          response.headers["Location"] = uri.to_s
          301
        when Fixnum
          uri
        else
          :l5
        end
      end

      # Previously existed?
      def k7
        decision_test(resource.previously_existed?, :k5, :l7)
      end

      # Etag in if-none-match?
      def k13
        request_etags = request.if_none_match.split(/\s*,\s*/).map {|etag| ETag.new(etag) }
        request_etags.include?(ETag.new(resource.generate_etag)) ? :j18 : :l13
      end

      # Moved temporarily?
      def l5
        case uri = resource.moved_temporarily?
        when String, URI
          response.headers["Location"] = uri.to_s
          307
        when Fixnum
          uri
        else
          :m5
        end
      end

      # POST?
      def l7
        request.post? ? :m7 : 404
      end

      # If-Modified-Since exists?
      def l13
        request.if_modified_since ? :l14 : :m16
      end

      # IMS is valid date?
      def l14
        date = Time.httpdate(request.if_modified_since)
        metadata['If-Modified-Since'] = date
      rescue ArgumentError
        :m16
      else
        :l15
      end

      # IMS > Now?
      def l15
        metadata['If-Modified-Since'] > Time.now ? :m16 : :l17
      end

      # Last-Modified > IMS?
      def l17
        resource.last_modified.nil? || resource.last_modified > metadata['If-Modified-Since'] ? :m16 : 304
      end

      # POST?
      def m5
        request.post? ? :n5 : 410
      end

      # Server allows POST to missing resource?
      def m7
        decision_test(resource.allow_missing_post?, :n11, 404)
      end

      # DELETE?
      def m16
        request.delete? ? :m20 : :n16
      end

      # DELETE enacted immediately? (Also where DELETE is forced.)
      def m20
        decision_test(resource.delete_resource, :m20b, 500)
      end

      # Did the DELETE complete?
      def m20b
        decision_test(resource.delete_completed?, :o20, 202)
      end

      # Server allows POST to missing resource?
      def n5
        decision_test(resource.allow_missing_post?, :n11, 410)
      end

      # Redirect?
      def n11
        # Stage1
        if resource.post_is_create?
          case uri = resource.create_path
          when nil
            raise InvalidResource, t('create_path_nil', :class => resource.class)
          when URI, String
            base_uri = resource.base_uri || request.base_uri
            new_uri = URI.join(base_uri.to_s, uri)
            request.disp_path = new_uri.path
            response.headers['Location'] = new_uri.to_s
            result = accept_helper
            return result if Fixnum === result
          end
        else
          case result = resource.process_post
          when true
            encode_body_if_set
          when Fixnum
            return result
          else
            raise InvalidResource, t('process_post_invalid', :result => result.inspect)
          end
        end
        if response.is_redirect?
          if response.headers['Location']
            303
          else
            raise InvalidResource, t('do_redirect')
          end
        else
          :p11
        end
      end

      # POST?
      def n16
        request.post? ? :n11 : :o16
      end

      # Conflict?
      def o14
        if resource.is_conflict?
          409
        else
          res = accept_helper
          (Fixnum === res) ? res : :p11
        end
      end

      # PUT?
      def o16
        request.put? ? :o14 : :o18
      end

      # Multiple representations?
      # Also where body generation for GET and HEAD is done.
      def o18
        if request.get? || request.head?
          add_caching_headers
          content_type = metadata['Content-Type']
          handler = resource.content_types_provided.find {|ct, _| content_type.type_matches?(MediaType.parse(ct)) }.last
          result = resource.send(handler)
          if Fixnum === result
            result
          else
            response.body = result
            encode_body
            :o18b
          end
        else
          :o18b
        end
      end

      # Multiple choices?
      def o18b
        decision_test(resource.multiple_choices?, 300, 200)
      end

      # Response includes an entity?
      def o20
        has_response_body? ? :o18 : 204
      end

      # Conflict?
      def p3
        if resource.is_conflict?
          409
        else
          res = accept_helper
          (Fixnum === res) ? res : :p11
        end
      end

      # New resource?
      def p11
        !response.headers["Location"] ? :o20 : 201
      end

    end # module Flow
  end # module Decision
end # module Webmachine
