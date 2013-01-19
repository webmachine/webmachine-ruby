require 'delegate'
require 'as/notifications/instrumenter'

module Webmachine
  module Events
    class InstrumentedEvent < SimpleDelegator
      def initialize(*args)
        super(AS::Notifications::Event.new(*args))
      end
    end
  end
end
