require 'webmachine/configuration'
require 'webmachine/dispatcher'

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
    include Configurable

    attr_reader :configuration
    attr_reader :dispatcher

    # Create an Application instance
    #
    # An instance of application contains Adapter configuration and
    # a Dispatcher instance which can be configured with Routes.
    # 
    # @param [Webmachine::Configuration] configuration
    #   a Webmachine::Configuration
    def initialize(configuration = Configuration.default)
      @configuration = configuration
      @dispatcher = Dispatcher.new
      yield self if block_given?
    end

    def routes(&block)
      if block_given?
        dispatcher.instance_eval(&block)
        self
      else
        dispatcher.routes
      end
    end

    def run
      Adapters.const_get(configuration.adapter).run(configuration, dispatcher)
    end
  end
end
