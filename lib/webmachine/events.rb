require 'securerandom' # For AS::Notifications
require 'as/notifications'
require 'webmachine/events/instrumented_event'

module Webmachine
  # {Webmachine::Events} implements the
  # [ActiveSupport::Notifications](http://rubydoc.info/gems/activesupport/ActiveSupport/Notifications)
  # instrumentation API. It delegates to the configured backend.
  # The default backend is
  # [AS::Notifications](http://rubydoc.info/gems/as-notifications/AS/Notifications).
  #
  # # Published events
  #
  # Webmachine publishes some internal events by default. All of them use
  # the `wm.` prefix.
  #
  # ## `wm.dispatch` ({.instrument})
  #
  # The payload hash includes the following keys.
  #
  # * `:resource` - The resource class name
  # * `:request` - A copy of the request object
  # * `:code` - The response code
  #
  module Events
    class << self
      # The class that {Webmachine::Events} delegates all messages to.
      # (default [AS::Notifications](http://rubydoc.info/gems/as-notifications/AS/Notifications))
      #
      # It can be changed to an
      # [ActiveSupport::Notifications](http://rubydoc.info/gems/activesupport/ActiveSupport/Notifications)
      # compatible backend early in the application startup process.
      #
      # @example
      #   require 'webmachine'
      #   require 'active_support/notifications'
      #
      #   Webmachine::Events.backend = ActiveSupport::Notifications
      #
      #   Webmachine::Application.new {|app|
      #     # setup application
      #   }.run
      attr_accessor :backend

      # Publishes the given arguments to all listeners subscribed to the given
      # event name.
      # @param name [String] the event name
      # @example
      #   Webmachine::Events.publish('wm.foo', :hello => 'world')
      def publish(name, *args)
        backend.publish(name, *args)
      end

      # Instrument the given block by measuring the time taken to execute it
      # and publish it. Notice that events get sent even if an error occurs
      # in the passed-in block.
      #
      # If an exception happens during an instrumentation the payload will
      # have a key `:exception` with an array of two elements as value:
      # a string with the name of the exception class, and the exception
      # message. (when using the default
      # [AS::Notifications](http://rubydoc.info/gems/as-notifications/AS/Notifications)
      # backend)
      #
      # @param name [String] the event name
      # @param payload [Hash] the initial payload
      #
      # @example
      #   Webmachine::Events.instrument('wm.dispatch') do |payload|
      #     execute_some_method
      #
      #     payload[:custom_payload_value] = 'important'
      #   end
      def instrument(name, payload = {}, &block)
        backend.instrument(name, payload, &block)
      end

      # Subscribes to the given event name.
      #
      # @note The documentation of this method describes its behaviour with the
      #   default backed [AS::Notifications](http://rubydoc.info/gems/as-notifications/AS/Notifications).
      #   It can change if a different backend is used.
      #
      # @overload subscribe(name)
      #   Subscribing to an {.instrument} event. The block arguments can be
      #   passed to {Webmachine::Events::InstrumentedEvent}.
      #
      #   @param name [String, Regexp] the event name to subscribe to
      #   @yieldparam name [String] the event name
      #   @yieldparam start [Time] the event start time
      #   @yieldparam end [Time] the event end time
      #   @yieldparam event_id [String] the event id
      #   @yieldparam payload [Hash] the event payload
      #   @return [Object] the subscriber object (type depends on the backend implementation)
      #
      #   @example
      #     # Subscribe to all 'wm.dispatch' events
      #     Webmachine::Events.subscribe('wm.dispatch') {|*args|
      #       event = Webmachine::Events::InstrumentedEvent.new(*args)
      #     }
      #
      #     # Subscribe to all events that start with 'wm.'
      #     Webmachine::Events.subscribe(/wm\.*/) {|*args| }
      #
      # @overload subscribe(name)
      #   Subscribing to a {.publish} event.
      #
      #   @param name [String, Regexp] the event name to subscribe to
      #   @yieldparam name [String] the event name
      #   @yieldparam *args [Array] the published arguments
      #   @return [Object] the subscriber object (type depends on the backend implementation)
      #
      #   @example
      #     Webmachine::Events.subscribe('custom.event') {|name, *args|
      #       args #=> [obj1, obj2, {:num => 1}]
      #     }
      #
      #     Webmachine::Events.publish('custom.event', obj1, obj2, {:num => 1})
      #
      # @overload subscribe(name, listener)
      #   Subscribing with a listener object instead of a block. The listener
      #   object must respond to `#call`.
      #
      #   @param name [String, Regexp] the event name to subscribe to
      #   @param listener [#call] a listener object
      #   @return [Object] the subscriber object (type depends on the backend implementation)
      #
      #   @example
      #     class CustomListener
      #       def call(name, *args)
      #         # ...
      #       end
      #     end
      #
      #     Webmachine::Events.subscribe('wm.dispatch', CustomListener.new)
      #
      def subscribe(name, *args, &block)
        backend.subscribe(name, *args, &block)
      end

      # Subscribe to an event temporarily while the block runs.
      #
      # @note The documentation of this method describes its behaviour with the
      #   default backed [AS::Notifications](http://rubydoc.info/gems/as-notifications/AS/Notifications).
      #   It can change if a different backend is used.
      #
      # The callback in the following example will be called for all
      # "sql.active_record" events instrumented during the execution of the
      # block. The callback is unsubscribed automatically after that.
      #
      # @example
      #   callback = lambda {|name, *args| handle_event(name, *args) }
      #
      #   Webmachine::Events.subscribed(callback, 'sql.active_record') do
      #     call_active_record
      #   end
      def subscribed(callback, name, &block)
        backend.subscribed(callback, name, &block)
      end

      # Unsubscribes the given subscriber.
      #
      # @note The documentation of this method describes its behaviour with the
      #   default backed [AS::Notifications](http://rubydoc.info/gems/as-notifications/AS/Notifications).
      #   It can change if a different backend is used.
      #
      # @param subscriber [Object] the subscriber object (type depends on the backend implementation)
      # @example
      #   subscriber = Webmachine::Events.subscribe('wm.dispatch') {|*args| }
      #
      #   Webmachine::Events.unsubscribe(subscriber)
      def unsubscribe(subscriber)
        backend.unsubscribe(subscriber)
      end
    end

    self.backend = AS::Notifications
  end
end
