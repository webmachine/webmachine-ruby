module Webmachine
  module Events
    class Subscriber
      def initialize(pattern, listener)
        @pattern = pattern
        @listener = listener
      end

      def publish(name, *args)
        @listener.publish(name, *args)
      end

      def start(name, id, payload)
        @listener.start(name, id, payload)
      end

      def finish(name, id, payload)
        @listener.finish(name, id, payload)
      end

      def subscribed_to?(name)
        @pattern === '*' or @pattern === name.to_s
      end

      def matches?(subscriber_or_name)
        self === subscriber_or_name || (@pattern && @pattern === subscriber_or_name)
      end
    end
  end
end
