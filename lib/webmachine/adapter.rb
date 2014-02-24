module Webmachine

  # The abstract class for definining a Webmachine adapter.
  #
  # @abstract Subclass and override {#run} to implement a custom adapter.
  class Adapter

    # @return [Webmachine::Application] returns the application
    attr_reader :wm_app

    # @param [Webmachine::Application] wm_app the application
    def initialize(wm_app)
      @wm_app = wm_app
    end

    # Create a new adapter and run it.
    def self.run(wm_app)
      new(wm_app).run
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
