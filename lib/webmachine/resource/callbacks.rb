module Webmachine
  class Resource
    # These methods are the primary way your {Webmachine::Resource}
    # instance interacts with HTTP and the
    # {Webmachine::Decision::FSM}. Implementing a callback can change
    # the portions of the graph that are made available to your
    # application.
    module Callbacks
      # Does the resource exist? Returning a falsey value (false or nil)
      # will result in a '404 Not Found' response. Defaults to true.
      # @return [true,false] Whether the resource exists
      # @api callback
      def resource_exists?
        true
      end

      # Is the resource available? Returning a falsey value (false or
      # nil) will result in a '503 Service Not Available'
      # response. Defaults to true.  If the resource is only temporarily
      # not available, add a 'Retry-After' response header in the body
      # of the method.
      # @return [true,false]
      # @api callback
      def service_available?
        true
      end

      # Is the client or request authorized? Returning anything other than true
      # will result in a '401 Unauthorized' response.  Defaults to
      # true. If a String is returned, it will be used as the value in
      # the WWW-Authenticate header, which can also be set manually.
      # @param [String] authorization_header The contents of the
      #     'Authorization' header sent by the client, if present.
      # @return [true,false,String] Whether the client is authorized,
      #     and if not, the WWW-Authenticate header when a String.
      # @api callback
      def is_authorized?(authorization_header = nil)
        true
      end

      # Is the request or client forbidden? Returning a truthy value
      # (true or non-nil) will result in a '403 Forbidden' response.
      # Defaults to false.
      # @return [true,false] Whether the client or request is forbidden.
      # @api callback
      def forbidden?
        false
      end

      # If the resource accepts POST requests to nonexistent resources,
      # then this should return true. Defaults to false.
      # @return [true,false] Whether to accept POST requests to missing
      #     resources.
      # @api callback
      def allow_missing_post?
        false
      end

      # If the request is malformed, this should return true, which will
      # result in a '400 Malformed Request' response. Defaults to false.
      # @return [true,false] Whether the request is malformed.
      # @api callback
      def malformed_request?
        false
      end

      # If the URI is too long to be processed, this should return true,
      # which will result in a '414 Request URI Too Long'
      # response. Defaults to false.
      # @param [URI] uri the request URI
      # @return [true,false] Whether the request URI is too long.
      # @api callback
      def uri_too_long?(uri = nil)
        false
      end

      # If the Content-Type on PUT or POST is unknown, this should
      # return false, which will result in a '415 Unsupported Media
      # Type' response. Defaults to true.
      # @param [String] content_type the 'Content-Type' header sent by
      #     the client
      # @return [true,false] Whether the passed media type is known or
      #     accepted
      # @api callback
      def known_content_type?(content_type = nil)
        true
      end

      # If the request includes any invalid Content-* headers, this
      # should return false, which will result in a '501 Not
      # Implemented' response. Defaults to true.
      # @param [Hash] content_headers Request headers that begin with
      #     'Content-'
      # @return [true,false] Whether the Content-* headers are invalid
      #     or unsupported
      # @api callback
      def valid_content_headers?(content_headers = nil)
        true
      end

      # If the entity length on PUT or POST is invalid, this should
      # return false, which will result in a '413 Request Entity Too
      # Large' response. Defaults to true.
      # @param [Fixnum] length the size of the request body (entity)
      # @return [true,false] Whether the body is a valid length (not too
      #    large)
      # @api callback
      def valid_entity_length?(length = nil)
        true
      end

      # If the OPTIONS method is supported and is used, this method
      # should return a Hash of headers that should appear in the
      # response. Defaults to {}.
      # @return [Hash] headers to appear in the response
      # @api callback
      def options
        {}
      end

      # HTTP methods that are allowed on this resource. This must return
      # an Array of Strings in all capitals. Defaults to ['GET','HEAD'].
      # @return [Array<String>] allowed methods on this resource
      # @api callback
      def allowed_methods
        ['GET', 'HEAD']
      end

      # HTTP methods that are known to the resource. Like
      # {#allowed_methods}, this must return an Array of Strings in
      # all capitals. Default includes all standard HTTP methods. One
      # could override this callback to  allow additional methods,
      # e.g. WebDAV.
      # @return [Array<String>] known methods
      # @api callback
      def known_methods
        ['GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE', 'TRACE', 'CONNECT', 'OPTIONS']
      end

      # This method is called when a DELETE request should be enacted,
      # and should return true if the deletion succeeded. Defaults to false.
      # @return [true,false] Whether the deletion succeeded.
      # @api callback
      def delete_resource
        false
      end

      # This method is called after a successful call to
      # {#delete_resource} and should return false if the deletion was
      # accepted but cannot yet be guaranteed to have finished. Defaults
      # to true.
      # @return [true,false] Whether the deletion completed
      # @api callback
      def delete_completed?
        true
      end

      # If POST requests should be treated as a request to put content
      # into a (potentially new) resource as opposed to a generic
      # submission for processing, then this method should return
      # true. If it does return true, then {#create_path} will be called
      # and the rest of the request will be treated much like a PUT to
      # the path returned by that call.  Default is false.
      # @return [true,false] Whether POST creates a new resource
      # @api callback
      def post_is_create?
        false
      end

      # This will be called on a POST request if post_is_create? returns
      # true. The path returned should be a valid URI part following the
      # dispatcher prefix. That path will replace the previous one in
      # the return value of {Request#disp_path} for all subsequent
      # resource function calls in the course of this request.
      # @return [String, URI] the path to the new resource
      # @api callback
      def create_path
        nil
      end

      # This will be called after {#create_path} but before setting the
      # Location response header, and is used to determine the root
      # URI of the new resource. Default is nil, which uses the URI of
      # the request as the base.
      # @return [String, URI, nil]
      # @api callback
      def base_uri
        nil
      end

      # If post_is_create? returns false, then this will be called to
      # process any POST request. If it succeeds, it should return true.
      # @return [true,false,Fixnum] Whether the POST was successfully
      #    processed, or an alternate response code
      # @api callback
      def process_post
        false
      end

      # This should return an array of pairs where each pair is of the
      # form [mediatype, :handler] where mediatype is a String of
      # Content-Type format (or {Webmachine::MediaType}) and :handler
      # is a Symbol naming the method which can provide a resource
      # representation in that media type. For example, if a client
      # request includes an 'Accept' header with a value that does not
      # appear as a first element in any of the return pairs, then a
      # '406 Not Acceptable' will be sent.  Default is [['text/html',
      # :to_html]].
      # @return an array of mediatype/handler pairs
      # @api callback
      def content_types_provided
        [['text/html', :to_html]]
      end

      # Similarly to content_types_provided, this should return an array
      # of mediatype/handler pairs, except that it is for incoming
      # resource representations -- for example, PUT requests. Handler
      # functions usually want to use {Request#body} to access the
      # incoming entity.
      # @return [Array] an array of mediatype/handler pairs
      # @api callback
      def content_types_accepted
        []
      end

      # If this is anything other than nil, it must be an array of pairs
      # where each pair is of the form Charset, Converter where Charset
      # is a string naming a charset and Converter is an arity-1 method
      # in the resource which will be called on the produced body in a
      # GET and ensure that it is in Charset.
      # @return [nil, Array] The provided character sets and encoder
      #     methods, or nothing.
      # @api callback
      def charsets_provided
        nil
      end

      # This should return a list of language tags provided by the
      # resource. Default is the empty Array, in which the content is
      # in no specific language.
      # @return [Array<String>] a list of provided languages
      # @api callback
      def languages_provided
        []
      end

      # This should receive the chosen language and do something with
      # it that is resource-specific. The default is to store the
      # value in the @language instance variable.
      # @param [String] lang the negotiated language
      # @api callback
      def language_chosen(lang)
        @language = lang
      end

      # This should return a hash of encodings mapped to encoding
      # methods for Content-Encodings your resource wants to
      # provide. The encoding will be applied to the response body
      # automatically by Webmachine. A number of built-in encodings
      # are provided in the {Encodings} module. Default includes only
      # the 'identity' encoding.
      # @return [Hash] a hash of encodings and encoder methods/procs
      # @api callback
      # @see Encodings
      def encodings_provided
        {"identity" => :encode_identity }
      end

      # If this method is implemented, it should return a list of
      # strings with header names that should be included in a given
      # response's Vary header. The standard conneg headers (Accept,
      # Accept-Encoding, Accept-Charset, Accept-Language) do not need to
      # be specified here as Webmachine will add the correct elements of
      # those automatically depending on resource behavior. Default is
      # [].
      # @api callback
      # @return [Array<String>] a list of variance headers
      def variances
        []
      end

      # If this returns true, the client will receive a '409 Conflict'
      # response. This is only called for PUT requests. Default is false.
      # @api callback
      # @return [true,false] whether the submitted entity is in conflict
      #     with the current state of the resource
      def is_conflict?
        false
      end

      # If this returns true, then it is assumed that multiple
      # representations of the response are possible and a single one
      # cannot be automatically chosen, so a 300 Multiple Choices will
      # be sent instead of a 200. Default is false.
      # @api callback
      # @return [true,false] whether the multiple representations are
      #     possible
      def multiple_choices?
        false
      end

      # If this resource is known to have existed previously, this
      # method should return true. Default is false.
      # @api callback
      # @return [true,false] whether the resource existed previously
      def previously_existed?
        false
      end

      # If this resource has moved to a new location permanently, this
      # method should return the new location as a String or
      # URI. Default is to return false.
      # @api callback
      # @return [String,URI,false] the new location of the resource, or
      #    false
      def moved_permanently?
        false
      end

      # If this resource has moved to a new location temporarily, this
      # method should return the new location as a String or
      # URI. Default is to return false.
      # @api callback
      # @return [String,URI,false] the new location of the resource, or
      #    false
      def moved_temporarily?
        false
      end

      # This method should return the last modified date/time of the
      # resource which will be added as the Last-Modified header in the
      # response and used in negotiating conditional requests. Default
      # is nil.
      # @api callback
      # @return [Time,DateTime,Date,nil] the last modified time
      def last_modified
        nil
      end

      # If the resource expires, this method should return the date/time
      # it expires. Default is nil.
      # @api callback
      # @return [Time,DateTime,Date,nil] the expiration time
      def expires
        nil
      end

      # If this returns a value, it will be used as the value of the
      # ETag header and for comparison in conditional requests. Default
      # is nil.
      # @api callback
      # @return [String,nil] the entity tag for this resource
      def generate_etag
        nil
      end

      # This method is called just before the final response is
      # constructed and sent. The return value is ignored, so any effect
      # of this method must be by modifying the response.
      # @api callback
      def finish_request; end

      #
      # This method is called when an exception is raised within a subclass of
      # {Webmachine::Resource}.
      #
      # @param [Exception] e
      #   The exception.
      #
      # @return [void]
      #
      # @api callback
      #
      def handle_exception(e)
        response.error = [e.message, e.backtrace].flatten.join("\n    ")
        Webmachine.render_error(500, request, response)
      end

      # This method is called when verifying the Content-MD5 header
      # against the request body. To do your own validation, implement
      # it in this callback, returning true or false. To bypass header
      # validation, simply return true.  Default is nil, which will
      # invoke Webmachine's default validation.
      # @api callback
      # @return [true,false,nil] Whether the Content-MD5 header
      #     validates against the request body
      def validate_content_checksum
        nil
      end

    end # module Callbacks
  end # class Resource
end # module Webmachine
