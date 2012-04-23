module Webmachine
  module Trace
    # This module is injected into {Webmachine::Decision::FSM} when
    # tracing is enabled for a resource, enabling the capturing of
    # traces.
    module FSM
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
    end
  end
end
