module Webmachine
  module Trace
    # This module is injected into {Webmachine::Decision::FSM} when
    # tracing is enabled for a resource, enabling the capturing of
    # traces.
    module FSM
      # Adds the request to the trace.
      # @param [Webmachine::Request] request the request to be traced
      def trace_request(request)
        response.trace << {
          :type => :request,
          :method => request.method,
          :path => request.uri.request_uri.to_s,
          :headers => request.headers,
          :body => request.body.to_s
        }
      end

      # Adds the response to the trace and then commits the trace to
      # separate storage which can be discovered by the debugger.
      # @param [Webmachine::Response] response the response to be traced
      def trace_response(response)
        response.trace << {
          :type => :response,
          :code => response.code.to_s,
          :headers => response.headers,
          :body => trace_response_body(response.body)
        }
      ensure
        Trace.record(resource.object_id.to_s, response.trace)
      end

      # Adds a decision to the trace.
      # @param [Symbol] decision the decision being processed
      def trace_decision(decision)
        response.trace << {:type => :decision, :decision => decision}
      end

      # Overrides the default resource accessor so that incoming
      # callbacks are traced.
      def resource
        @resource_proxy ||= ResourceProxy.new(@resource)
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
