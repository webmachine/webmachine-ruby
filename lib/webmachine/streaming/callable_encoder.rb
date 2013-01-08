module Webmachine
  module Streaming
    # Implements a streaming encoder for callable bodies, such as
    # Proc. (essentially futures)
    # @api private
    class CallableEncoder < Encoder
      # Encodes the output of the body Proc.
      # @return [String]
      def call
        resource.send(encoder, resource.send(charsetter, body.call.to_s))
      end

      # Converts this encoder into a Proc.
      # @return [Proc] a closure that wraps the {#call} method
      # @see #call
      def to_proc
        method(:call).to_proc
      end
    end # class CallableEncoder
  end
end
