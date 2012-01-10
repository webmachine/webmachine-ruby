module Webmachine

  # The abstract class for definining a Webmachine adapter.
  #
  # @abstract Subclass and override {#run} to implement a custom adapter.
  class Adapter

    # @return [Webmachine::Configuration] the application's configuration.
    attr_reader :configuration

    # @return [Webmachine::Dispatcher] the application's dispatcher.
    attr_reader :dispatcher

    # @param [Webmachine::Configuration] configuration the application's
    # configuration.
    # @param [Webmachine::Dispatcher] dispatcher the application's dispatcher.
    def initialize(configuration, dispatcher)
      @configuration = configuration
      @dispatcher    = dispatcher
    end

    # Create a new adapter and run it.
    def self.run(configuration, dispatcher)
      new(configuration, dispatcher).run
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
