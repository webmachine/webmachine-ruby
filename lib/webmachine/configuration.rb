module Webmachine
  # A simple configuration container for items that are used across
  # multiple web server adapters. Typically set using
  # {Webmachine::configure}. If not set by your application, the
  # defaults will be filled in when {Webmachine::run} is called.
  # @attr [String] ip the interface to bind to, defaults to "0.0.0.0"
  #    (all interfaces)
  # @attr [Fixnum] port the port to bind to, defaults to 8080
  # @attr [Symbol] adapter the adapter to use, defaults to :WEBrick
  # @attr [Hash] adapter_options adapter-specific options, defaults to {}
  Configuration = Struct.new(:ip, :port, :adapter, :adapter_options)

  # @return [Configuration] the default configuration
  def Configuration.default
    if defined?(RSpec)
      server = TCPServer.new('0.0.0.0', 0)
      port = $testmachine_port = server.addr[1]
      server.close
    else
      port = 8080
    end

    new("0.0.0.0", port, :WEBrick, {})
  end

  # Yields the current configuration to the passed block.
  # @yield [config] a block that will modify the configuration
  # @yieldparam [Configuration] config the adapter configuration
  # @return self
  # @see Application#configure
  def self.configure(&block)
    application.configure(&block)
    self
  end

  # @return [Configuration] the current configuration
  # @see Application#configuration
  def self.configuration
    application.configuration
  end

  # Sets the current configuration
  # @param [Configuration] configuration the new config
  # @see Application#configuration=
  def self.configuration=(configuration)
    application.configuration = configuration
  end
end # Webmachine
