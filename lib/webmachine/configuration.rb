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
  def Configuration.default
    new("0.0.0.0", 8080, :WEBrick, {})
  end

  def self.configure(&block)
    application.configure(&block)
    self
  end

  def self.configuration
    application.configuration
  end

  def self.configuration=(configuration)
    application.configuration = configuration
  end
end
