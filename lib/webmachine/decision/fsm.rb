module Webmachine
  module Decision
    class FSM
      include Flow
      include Helpers
      attr_reader :resource, :request, :response, :metadata
      
      def initialize(resource, request, response)
        @resource, @request, @response = resource, request, response
        @metadata = {}
      end

      def run
        begin
          state = Flow::START
          loop do
            result = send(state)
            case result
            when Fixnum # Response code
              respond(result)
              return
            when Symbol # Next state
              state = result
            else # You bwoke it
              raise InvalidResource.new(state, result)
            end
          end
        rescue => e # Handle all exceptions without crashing the server
          error_response(e, state)
        end
      end

      private
      def respond(code, headers={})
        response.headers.merge!(headers)
        end_time = Time.now
        case code
        when 404
          # TODO: implement render_error
          Webmachine.render_error(code, request, response)
        when 304
          response.headers.delete['Content-Type']
          if etag = resource.generate_etag
            response.headers['ETag'] = ensure_quoted_header(etag)
          end
          if expires = resource.expires
            response.headers['Expires'] = Time.httpdate(expires)
          end          
        end
        response.code = code
        resource.finish_request
        # TODO: add logging/tracing
      end

      # TODO: implement handling error responses
      def error_response(exception, state)
      end
    end
  end
end
