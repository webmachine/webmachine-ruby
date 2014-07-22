require 'fiber'

module Webmachine
  module Streaming
    # Implements a streaming encoder for Fibers with the same API as the
    # EnumerableEncoder. This will resume the Fiber until it terminates
    # or returns a falsey value.
    # @api private
    class FiberEncoder < Encoder
      include Enumerable

      # Iterates over the body by yielding to the fiber.
      # @api private
      def each
        while body.alive? && chunk = body.resume
          yield resource.send(encoder, resource.send(charsetter, chunk.to_s))
        end
      end
    end # class FiberEncoder
  end
end
