require 'securerandom' # For AS::Notifications
require 'active_support/notifications'
require 'webmachine/events/instrumented_event'

module Webmachine
  module Events
    class << self
      attr_accessor :backend

      def publish(name, *args)
        backend.publish(name, *args)
      end

      def instrument(name, payload = {}, &block)
        backend.instrument(name, payload, &block)
      end

      def subscribe(*args, &block)
        backend.subscribe(*args, &block)
      end

      def subscribed(callback, *args, &block)
        backend.subscribed(callback, *args, &block)
      end

      def unsubscribe(subscriber)
        backend.unsubscribe(subscriber)
      end
    end

    self.backend = ActiveSupport::Notifications
  end
end
