module Webmachine
  module Trace
    # This module is injected into {Webmachine::Decision::FSM} when
    # tracing is enabled for a resource, enabling the capturing of
    # traces.
    module FSM
      # Overrides the default resource accessor so that incoming
      # callbacks are traced.
      def initialize(_resource, _request, _response)
        if trace?
          class << self
            def resource
              @resource_proxy ||= ResourceProxy.new(@resource)
            end
          end
        end
      end

      def trace?
        Trace.trace?(@resource)
      end

      # Adds the request to the trace.
      # @param [Webmachine::Request] request the request to be traced
      def trace_request(request)
        if trace?
          response.trace << {
            type: :request,
            method: request.method,
            path: request.uri.request_uri.to_s,
            headers: request.headers,
            body: request.body.to_s
          }
        end
      end

      # Adds the response to the trace and then commits the trace to
      # separate storage which can be discovered by the debugger.
      # @param [Webmachine::Response] response the response to be traced
      def trace_response(response)
        if trace?
          response.trace << {
            type: :response,
            code: response.code.to_s,
            headers: response.headers,
            body: trace_response_body(response.body)
          }
        end
      ensure
        if trace?
          Webmachine::Events.publish('wm.trace.record', {
            trace_id: resource.object_id.to_s,
            trace: response.trace
          })
        end
      end

      # Adds a decision to the trace.
      # @param [Symbol] decision the decision being processed
      def trace_decision(decision)
        response.trace << {type: :decision, decision: decision} if trace?
      end

      private

      # Works around streaming encoders where possible
      def trace_response_body(body)
        case body
        when Streaming::FiberEncoder
          # TODO: figure out how to properly rewind or replay the
          # fiber
          body.inspect
        when Streaming::EnumerableEncoder
          body.body.join
        when Streaming::CallableEncoder
          body.body.call.to_s
        when Streaming::IOEncoder
          body.body.inspect
        else
          body.to_s
        end
      end
    end
  end
end
