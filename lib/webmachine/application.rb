require 'forwardable'
require 'webmachine/configuration'
require 'webmachine/dispatcher'
require 'webmachine/events'

module Webmachine
  # How to get your Webmachine app running:
  #
  #   MyApp = Webmachine::Application.new do |app|
  #     app.routes do
  #       add ['*'], AssetResource
  #     end
  #
  #     app.configure do |config|
  #       config.port = 8888
  #     end
  #   end
  #
  #   MyApp.run
  #
  class Application
    extend Forwardable

    def_delegators :dispatcher, :add_route

    # @return [Configuration] the current configuration
    attr_accessor :configuration

    # @return [Dispatcher] the current dispatcher
    attr_reader :dispatcher

    # Create an Application instance
    #
    # An instance of application contains Adapter configuration and
    # a Dispatcher instance which can be configured with Routes.
    #
    # @param [Webmachine::Configuration] configuration
    #   a Webmachine::Configuration
    #
    # @yield [app]
    #   a block in which to configure this Application
    # @yieldparam [Application]
    #   the Application instance being initialized
    def initialize(configuration = Configuration.default, dispatcher = Dispatcher.new)
      @configuration = configuration
      @dispatcher    = dispatcher

      yield self if block_given?
    end

    # Starts this Application serving requests
    def run
      adapter.run
    end

    # @return an instance of the configured web-server adapter
    # @see Adapters
    def adapter
      @adapter ||= adapter_class.new(self)
    end

    # @return an instance of the configured web-server adapter
    # @see Adapters
    def adapter_class
      Adapters.const_get(configuration.adapter)
    end

    # Evaluates the passed block in the context of {Webmachine::Dispatcher}
    # for use in adding a number of routes at once.
    #
    # @return [Application, Array<Route>]
    #   self if configuring, or an Array of Routes otherwise
    #
    # @see Webmachine::Dispatcher#add_route
    def routes(&block)
      if block_given?
        dispatcher.instance_eval(&block)
        self
      else
        dispatcher.routes
      end
    end

    # Configure the web server adapter via the passed block
    #
    # Returns the receiver so you can chain it with Application#run
    #
    # @yield [config]
    #   a block in which to set configuration values
    # @yieldparam [Configuration]
    #   config the Configuration instance
    #
    # @return [Application] self
    def configure
      yield configuration if block_given?
      self
    end

    # @return [Configuration] the current configuration
    def configuration
      @configuration ||= Configuration.default
    end
  end

  # @return [Application] the default global Application
  def self.application
    @application ||= Application.new
  end
end
