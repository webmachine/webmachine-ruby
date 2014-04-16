require 'webmachine/decision/helpers'
require 'webmachine/translation'

module Webmachine
  module Decision
    # Implements the finite-state machine described by the Webmachine
    # sequence diagram.
    class FSM
      include Flow
      include Helpers
      include Translation

      attr_reader :resource, :request, :response, :metadata

      def initialize(resource, request, response)
        @resource, @request, @response = resource, request, response
        @metadata = {}
        initialize_tracing
      end

      # Processes the request, iteratively invoking the decision methods in {Flow}.
      def run
        state = Flow::START
        trace_request(request)
        loop do
          trace_decision(state)
          result = handle_exceptions { send(state) }
          case result
          when Fixnum # Response code
            respond(result)
            break
          when Symbol # Next state
            state = result
          else # You bwoke it
            raise InvalidResource, t('fsm_broke', :state => state, :result => result.inspect)
          end
        end
      rescue Exception => e
        Webmachine.render_error(500, request, response, :message => e.message)
      ensure
        trace_response(response)
      end

      private

      def handle_exceptions
        yield
      rescue MalformedRequest => e
        Webmachine.render_error(400, request, response, :message => e.message)
        400
      rescue Exception => e
        resource.handle_exception(e)
        500
      end

      def respond(code, headers={})
        response.code = code
        response.headers.merge!(headers)
        case code
        when 404
          Webmachine.render_error(code, request, response)
        when 304
          response.headers.delete('Content-Type')
          add_caching_headers
        end

        response.code = handle_exceptions do
          resource.finish_request
          response.code
        end

        ensure_content_length(response)
        ensure_date_header(response)
      end

      # When tracing is disabled, this does nothing.
      def trace_decision(state); end
      # When tracing is disabled, this does nothing.
      def trace_request(request); end
      # When tracing is disabled, this does nothing.
      def trace_response(response); end

      def initialize_tracing
        extend Trace::FSM if Trace.trace?(resource)
      end
    end # class FSM
  end # module Decision
end # module Webmachine
