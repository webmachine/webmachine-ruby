module Webmachine
  module Trace
    class Listener
      def call(name, payload)
        key = payload.fetch(:trace_id)
        trace = payload.fetch(:trace)

        Webmachine::Trace.record(key, trace)
      end
    end
  end
end
