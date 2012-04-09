module Webmachine
  module Trace
    class ResourceProxy
      attr_reader :resource

      def initialize(resource)
        @resource = resource
      end

      # Create wrapper methods for every exposed callback
      Webmachine::Resource::Callbacks.instance_methods(false).each do |c|
        define_method c do |*args|
          proxy_callback c, *args
        end
      end

      private
      # Proxy a given callback to the inner resource, decorating with traces
      def proxy_callback(callback, *args)
        # Log inputs and attempt
        resource.response.trace << attempt(callback, args)
        # Do the call
        begin
          _result = resource.send(callback, *args)
          resource.response.trace << result(_result)
        rescue
          resource.response.trace << exception($!)
          raise
        end
      end

      def attempt(callback, args)
        log = {:type => :attempt}
        method = resource.method(callback)
        if method.owner == ::Webmachine::Resource::Callbacks
          log[:name] = "(default)##{method.name}"
        else
          log[:name] = "#{method.owner.name}##{method.name}"
          log[:source] = method.source_location.join(":")
        end
        unless args.empty?
          log[:args] = args
        end
        log
      end

      def result(result)
        {:type => :result, :value => result}
      end

      def exception(e)
        {:type => :exception,
          :backtrace => e.backtrace.reject {|line| line.include? __FILE__ },
          :message => e.message }
      end
    end
  end
end
