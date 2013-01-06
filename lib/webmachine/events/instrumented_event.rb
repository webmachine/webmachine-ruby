require 'delegate'
require 'active_support/notifications/instrumenter'

module Webmachine
  module Events
    class InstrumentedEvent < SimpleDelegator
      def initialize(*args)
        super(ActiveSupport::Notifications::Event.new(*args))
      end
    end
  end
end
