module Webmachine
  module Trace
    # The default trace listener that calls {Webmachine::Trace.record} to
    # commit the trace to storage.
    class Listener
      def publish(name, payload)
        key = payload.fetch(:trace_id)
        trace = payload.fetch(:trace)

        Webmachine::Trace.record(key, trace)
      end

      def start(*args); end
      def finish(*args); end
    end
  end
end
