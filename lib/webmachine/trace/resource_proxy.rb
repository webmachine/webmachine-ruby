require 'webmachine/resource'

module Webmachine
  module Trace
    # This class is injected into the decision FSM as a stand-in for
    # the resource when tracing is enabled. It proxies all callbacks
    # to the resource so that they get logged in the trace.
    class ResourceProxy
      # @return [Webmachine::Resource] the wrapped resource
      attr_reader :resource

      # Callback methods that can return data that refers to
      # user-defined callbacks that are not in the canonical set,
      # including body-producing or accepting methods, encoders and
      # charsetters.
      CALLBACK_REFERRERS = [:content_types_accepted, :content_types_provided,
        :encodings_provided, :charsets_provided]

      # Creates a {ResourceProxy} that decorates the passed
      # {Webmachine::Resource} such that callbacks invoked by the
      # {Webmachine::Decision::FSM} will be logged in the response's
      # trace.
      def initialize(resource)
        @resource = resource
        @dynamic_callbacks = Module.new
        extend @dynamic_callbacks
      end

      # Create wrapper methods for every exposed callback
      Webmachine::Resource::Callbacks.instance_methods(false).each do |c|
        define_method c do |*args|
          proxy_callback c, *args
        end
      end

      def charset_nop(*args)
        proxy_callback :charset_nop, *args
      end

      # Calls the resource's finish_request method and then sets the trace id
      # header in the response.
      def finish_request(*args)
        proxy_callback :finish_request, *args
      ensure
        resource.response.headers['X-Webmachine-Trace-Id'] = object_id.to_s
      end

      private

      # Proxy a given callback to the inner resource, decorating with traces
      def proxy_callback(callback, *args)
        # Log inputs and attempt
        resource.response.trace << attempt(callback, args)
        # Do the call
        _result = resource.send(callback, *args)
        add_dynamic_callback_proxies(_result) if CALLBACK_REFERRERS.include?(callback.to_sym)
        resource.response.trace << result(_result)
        _result
      rescue => exc
        exc.backtrace.reject! { |s| s.include?(__FILE__) }
        resource.response.trace << exception(exc)
        raise
      end

      # Creates a log entry for the entry to a resource callback.
      def attempt(callback, args)
        log = {type: :attempt}
        method = resource.method(callback)
        if method.owner == ::Webmachine::Resource::Callbacks
          log[:name] = "(default)##{method.name}"
        else
          log[:name] = "#{method.owner.name}##{method.name}"
          log[:source] = method.source_location.join(':') if method.respond_to?(:source_location)
        end
        unless args.empty?
          log[:args] = args
        end
        log
      end

      # Creates a log entry for the result of a resource callback
      def result(result)
        {type: :result, value: result}
      end

      # Creates a log entry for an exception that was raised from a callback
      def exception(e)
        {type: :exception,
         class: e.class.name,
         backtrace: e.backtrace,
         message: e.message}
      end

      # Adds proxy methods for callbacks that are dynamically referred to.
      def add_dynamic_callback_proxies(pairs)
        pairs.to_a.each do |(_, m)|
          unless respond_to?(m)
            @dynamic_callbacks.module_eval do
              define_method m do |*args|
                proxy_callback m, *args
              end
            end
          end
        end
      end
    end
  end
end
