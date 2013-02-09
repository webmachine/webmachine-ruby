require 'delegate'
require 'as/notifications/instrumenter'

module Webmachine
  module Events
    # {Webmachine::Events::InstrumentedEvent} delegates to
    # [AS::Notifications::Event](http://rubydoc.info/gems/as-notifications/AS/Notifications/Event).
    #
    # The class
    # [AS::Notifications::Event](http://rubydoc.info/gems/as-notifications/AS/Notifications/Event)
    # is able to take the arguments of an {Webmachine::Events.instrument} event
    # and provide an object-oriented interface to that data.
    class InstrumentedEvent < SimpleDelegator
      def initialize(*args)
        super(AS::Notifications::Event.new(*args))
      end
    end
  end
end
