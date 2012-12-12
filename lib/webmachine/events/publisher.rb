require 'webmachine/events/subscriber'

module Webmachine
  module Events
    module Publisher
      class Fanout
        def initialize
          @subscribers = []
        end

        def subscribe(pattern, listener)
          Subscriber.new(pattern, listener).tap do |subscriber|
            @subscribers << subscriber
          end
        end

        def unsubscribe(subscriber)
          @subscribers.reject! {|s| s.matches?(subscriber) }
        end

        def publish(name, *args)
          subscribers_for(name).each {|s| s.publish(name, *args) }
        end

        def start(name, id, payload)
          subscribers_for(name).each {|s| s.start(name, id, payload) }
        end

        def finish(name, id, payload)
          subscribers_for(name).each {|s| s.finish(name, id, payload) }
        end

        def has_subscriptions?(name)
          subscribers_for(name).any?
        end

        private

        def subscribers_for(name)
          @subscribers.select {|s| s.subscribed_to?(name) }
        end
      end
    end
  end
end
