require 'webmachine/events/publisher'
require 'webmachine/events/instrumenter'

module Webmachine
  module Events
    class << self
      attr_accessor :publisher

      def subscribe(*args, &block)
        publisher.subscribe(*args, &block)
      end

      def unsubscribe(subscriber)
        publisher.unsubscribe(subscriber)
      end

      def publish(name, *args)
        publisher.publish(name, *args)
      end

      def instrument(name, payload = {})
        if publisher.has_subscriptions?(name)
          instrumenter.instrument(name, payload) { yield(payload) if block_given? }
        else
          yield(payload) if block_given?
        end
      end

      private

      def instrumenter
        Thread.current[:"instrumenter_#{publisher.object_id}"] ||= Instrumenter.new(publisher)
      end

    end

    self.publisher = Publisher::Fanout.new
  end
end
