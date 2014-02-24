module Webmachine

  # The abstract class for definining a Webmachine adapter.
  #
  # @abstract Subclass and override {#run} to implement a custom adapter.
  class Adapter

    # @return [Webmachine::Application] returns the application
    attr_reader :application

    # @param [Webmachine::Application] application the application
    def initialize(application)
      @application = application
    end

    # Create a new adapter and run it.
    def self.run(application)
      new(application).run
    end

    # Start the adapter.
    #
    # @abstract Subclass and override {#run} to implement a custom adapter.
    # @raise [NotImplementedError]
    def run
      raise NotImplementedError
    end

  end
end
