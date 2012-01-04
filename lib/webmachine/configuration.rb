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

  class << self
    # @return [Configuration] the current configuration
    attr_accessor :configuration
  end

  # Sets configuration for the web server via the passed
  # block. Returns Webmachine so you can chain it with
  # Webmachine.run.
  # @yield [config] a block in which to set configuration values
  # @yieldparam [Configuration] config the Configuration instance
  # @return [Webmachine]
  def self.configure
    @configuration ||= Configuration.new("0.0.0.0", 8080, :WEBrick, {})
    yield @configuration if block_given?
    self
  end
end # module Webmachine
