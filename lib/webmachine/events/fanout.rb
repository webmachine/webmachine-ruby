module Webmachine
  module Events
    class Fanout
      def initialize
        @subscribers = []
      end

      def publish(name, *args)
        subscribers_for(name).each {|s| s.publish(name, *args) }
      end

      def subscribe(pattern, block = Proc.new)
        Subscriber.new(pattern, block).tap do |subscriber|
          @subscribers << subscriber
        end
      end

      def unsubscribe(subscriber)
        @subscribers.reject! {|s| s.matches?(subscriber) }
      end

      def subscribers_for(name)
        @subscribers.select {|s| s.subscribed_to?(name) }
      end

      class Subscriber
        def initialize(pattern, listener)
          @pattern = pattern
          @listener = listener
        end

        def subscribed_to?(pattern)
          @pattern === pattern
        end

        def publish(name, *args)
          @listener.call(name, *args)
        end

        def matches?(subscriber_or_name)
          self === subscriber_or_name || (@pattern && @pattern === subscriber_or_name)
        end
      end
    end
  end
end
