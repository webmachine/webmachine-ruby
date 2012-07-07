module Webmachine
  class Resource
    # Contains {Resource} methods related to the visual debugger.
    module Tracing
      # Whether this resource should be traced. By default, tracing is
      # disabled, but you can override it by setting the @trace
      # instance variable in the initialize method, or by overriding
      # this method. When enabled, traces can be visualized using the
      # web debugging interface.
      # @example
      #   def initialize
      #     @trace = true
      #   end
      # @api callback
      def trace?
        !!@trace
      end
    end
  end
end
