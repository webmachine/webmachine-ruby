module Webmachine
  # Namespace for classes that support streaming response bodies.
  module Streaming
  end # module Streaming
end # module Webmachine

require 'webmachine/streaming/encoder'
require 'webmachine/streaming/enumerable_encoder'
require 'webmachine/streaming/io_encoder'
require 'webmachine/streaming/callable_encoder'
require 'webmachine/streaming/fiber_encoder'
