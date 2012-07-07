require 'webmachine/decision/helpers'
require 'webmachine/decision/fsm'
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
          result = send(state)
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
      rescue MalformedRequest => malformed
        Webmachine.render_error(400, request, response, :message => malformed.message)
        respond(400)
      rescue Exception => e # Handle all exceptions without crashing the server
        code = resource.handle_exception(e)
        code = (100...600).include?(code) ? (code) : (500)
        respond(code)
      end

      private

      def respond(code, headers={})
        response.headers.merge!(headers)
        case code
        when 404
          Webmachine.render_error(code, request, response)
        when 304
          response.headers.delete('Content-Type')
          add_caching_headers
        end
        response.code = code
        resource.finish_request
        ensure_content_length
        trace_response(response)
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
