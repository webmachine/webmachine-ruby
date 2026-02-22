module Webmachine
  module Trace
    # Implements a trace storage using the pstore gem. To use this trace store,
    # add `pstore` to your Gemfile and specify the :pstore engine and a path
    # where it can store traces:
    # @example
    #   Webmachine::Trace.trace_store = :pstore, "/tmp/webmachine.trace"
    class PStoreTraceStore
      # @api private
      # @param [String] path where to store traces in a PStore
      def initialize(path)
        require 'pstore' # JIT load of the pstore gem. Avoid requiring the dependency when this class is not used.
        @pstore = PStore.new(path)
      end

      # Lists the recorded traces
      # @api private
      # @return [Array] a list of recorded traces
      def keys
        @pstore.transaction(true) { @pstore.roots }
      end

      # Fetches a trace from the store
      # @api private
      # @param [String] key the trace to fetch
      # @return [Array] a raw trace
      def fetch(key)
        @pstore.transaction(true) { @pstore[key] }
      end

      # Records a trace in the store
      # @api private
      def []=(key, trace)
        @pstore.transaction { @pstore[key] = trace }
      end
    end
  end
end
