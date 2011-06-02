module Webmachine
  module Decision
    # This module encapsulates all of the decisions in Webmachine's
    # flow-chart. These invoke {Resource} {Callbacks} to determine the
    # appropriate response code, headers, and body for the response.
    #
    # This module is included into {FSM}, which drives the processing
    # of the chart.
    # @see http://webmachine.basho.com/images/http-headers-status-v3.png
    module Flow
      def b13
        resource.service_available? ? :b12 : 503
      end

      # Known method?
      def b12
        resource.known_methods.include?(request.method) ? :b11 : 501
      end

      # URI too long?
      def b11
        resource.uri_too_long? ? 414 : :b10
      end

      # Method allowed?
      def b10
        if allowed_methods.include?(request.method)
          :b9
        else
          response.headers.add("Allow", allowed_methods.join(", "))
          405
        end
      end

      # Malformed?
      def b9
        resource.malformed_request? ? 400 : :b8
      end

      # Authorized?
      def b8
        result = resource.is_authorized?(request.authorization)
        case result
        when true
          :b7
        when String
          headers.add('WWW-Authenticate', result)
          401
        else
          401
        end
      end

      # Forbidden?
      def b7
        resource.forbidden? ? 403 : :b6
      end

      # Okay Content-* Headers?
      def b6
        resource.valid_content_headers?(headers) ? :b5 : 501
      end

      # Known Content-Type?
      def b5
        resource.known_content_type?(request.content_type) ? :b4 : 415
      end

      # Req Entity Too Large?
      def b4
        resource.valid_entity_length?(request.headers['Content-Length']) ? :b3 : 413
      end

      # OPTIONS?
      def b3
        if request.method == "OPTIONS"
          response.headers.merge!(resource.options)
          200
        else
          :c3
        end
      end

      # Accept exists?
      def c3        
        if !request.headers['Accept']
          types = resource.content_types_provided.map {|pair| pair.first }
          metadata.add("Content-Type", types.first)
          :d4
        else
          :c4
        end
      end

      # Acceptable media type available?
      def c4
        types = resource.content_types_provided.map {|pair| pair.first }
        chosen_type = Util.choose_media_type(types, request.headers['Accept'])
        if !chosen_type
          406
        else
          metadata['Content-Type'] = chosen_type
          :d4
        end
      end

      # Accept-Language exists?
      def d4
        request.headers['Accept-Language'] ? :e5 : :d5
      end

      # Acceptable language available
      def d5
        resource.language_available?(request.headers['Accept-Language']) ? :e5 : 406
      end

      # Accept-Charset exists?
      def e5
        if !request.headers['Accept-Charset']
          choose_charset("*") ? :f6 : 406
        else
          :e6
        end
      end

      # Acceptable Charset available?
      def e6
        choose_charset(request.headers['Accept-Charset']) ? :f6 : 406
      end

      # Accept-Encoding exists?
      # (also, set content-type header here, now that charset is chosen)
      def f6
        chosen_type = metadata['Content-Type']
        chosen_charset = metadata['Charset']
        chosen_type << "; charset=#{chosen_charset}" if chosen_charset
        response.headers['Content-Type'] = chosen_type
        if !accept_encoding
          choose_encoding("identity;q=1.0,*;q=0.5") ? :g7 : 406
        else
          :f7
        end
      end

      # Acceptable encoding available?
      def f7
        choose_encoding(request.headers['Accept-Encoding']) ? :g7 : 406
      end

      # Resource exists?
      def g7
        # This is the first place after all conneg, so set Vary here
        response.headers['Vary'] =  variances.join(", ") if variances.any?
        resource.resource_exists? ? :g8 : :h7
      end

      # If-Match exists?
      def g8
        request.if_match ? :g9 : :h10
      end

      # If-Match: * exists?
      def g9
        request.if_match == "*" ? :h10 : :g11
      end

      # ETag in If-Match
      def g11
        request_etag = Util.unquote_header(if_match)
        generate_etag == request_etag ? :h10 : 412
      end

      # If-Match exists?
      def h7
        if_match == "*" ? 412 : :i7
      end

      # If-Unmodified-Since exists?
      def h10
        if_unmodified_since ? :i12 : :h11
      end

      # If-Unmodified-Since is valid date?
      def h10
        begin
          set(:if_unmodified_since, Time.httpdate(if_unmodified_since))
        rescue ArgumentError
          :i12
        else
          :h12
        end
      end

      # Last-Modified > I-UM-S?
      def h12
        last_modified > if_unmodified_since ? 412 : :i12
      end

      # Moved permanently? (apply PUT to different URI)
      def i4
        if uri = moved_permanently?
          headers.add("Location", uri)
          301
        else
          :p3
        end
      end

      # PUT?
      def i7
        request_method == "PUT" ? :i4 : :k7
      end

      # If-none-match exists?
      def i12
        if_none_match ? :i13 : :l13
      end

      # If-none-match: * exists?
      def i13
        if_none_match == "*" ? :j18 : :k13
      end

      # GET or HEAD?
      def v3j18
        %w{GET HEAD}.include?(request_method) ? 304 : 412
      end

      # Moved permanently?
      def k5
        if uri = moved_permanently?
          headers.add("Location", uri)
          301
        else
          :l5
        end
      end

      # Previously existed?
      def k7
        previously_existed? ? :k5 : :l7
      end

      # Etag in if-none-match?
      def k13
        request_etag = Util.unquote_header(if_none_match)
        generate_etag == request_etag ? :j18 : :l13
      end

      # Moved temporarily?
      def l5
        if uri = moved_temporarily
          headers.add("Location", uri)
          307
        else
          :m5
        end
      end

      # POST?
      def l7
        request_method == "POST" ? :m7 : 404
      end

      # If-Modified-Since exists?
      def l13
        if_modified_since ? :l14 : :m16
      end

      # IMS is valid date?
      def l14
        begin
          set(:if_modified_since, Time.httpdate(if_modified_since))
          :l15
        rescue ArgumentError
          :m16
        end
      end

      # IMS > Now?
      def l15
        if_modified_since > Time.now.utc ? :m16 : :l17
      end

      # Last-Modified > IMS?
      def l17
        last_modified.nil? || last_modified > if_modified_since ? :m16 : 304
      end

      # POST?
      def m5
        request_method == "POST" ? :n5 : 410
      end

      # Server allows POST to missing resource?
      def m7
        allow_missing_post? ? :n11 : 404
      end

      # DELETE?
      def m16
        request_method == "DELETE" ? :m20 : :n16
      end

      # DELETE enacted immediately? (Also where DELETE is forced.)
      def m20
        delete_resource ? :m20b : 500
      end

      def m20b
        delete_completed? ? :o20 : 202
      end

      # Server allows POST to missing resource?
      def n5
        allow_missing_post? ? :n11 : 410
      end

      # Redirect?
      def n11
        #       stage1 = if post_is_create?
        #                  if uri = create_path
        #                    raise WebmachineError, "create_path is not a String" unless String === uri

        #                  else
        #                    raise WebmachineError, "post_is_create? is true by create_path does not return a String"
        #                  end
        #                else
        #                  _process_post = process_post
        #                  case _process_post
        #                  when true
        #                    encode_body_if_set
        #                    :stage1_ok
        #                  when Fixnum
        #                    _process_post
        #                  else
        #                    raise WebmachineError, "process_post failed"
        #                  end
        #                end

      end

      # POST?
      def n16
        request_method == "POST" ? :n11 : :o16
      end

      # Conflict?
      def o14
        if is_conflict?
          409
        else
          # accept_helper junk
        end
      end

      # PUT?
      def o16
        request_method == "PUT" ? :o14 : :o18
      end

      # Multiple representations?
      def o18
        if _build_body?
          headers.add("ETag", generate_etag) if generate_etag
          headers.add("Last-Modified", Time.httpdate(last_modified)) if last_modified
          headers.add("Expires", Time.httpdate(expires)) if expires
          _, meth = content_types_provided.find {|type,m| type == content_type }
          # THIS SHIT DOESNT TRANSLATE EXACTLY
          send(meth)
        else
          :o18b
        end
      end

      # Multiple choices?
      def o18b
        multiple_choices? ? 300 : 200
      end

      # Response includes an entity?
      def o20
        has_response_body? ? :o18 : 204
      end

      # Conflict?
      def p3
        if is_conflict?
          409
        else
          # accept_helper junk
        end
      end

      # New resource?
      def p11
        headers["Location"].blank? ? :o20 : 201
      end
    end
  end
end
