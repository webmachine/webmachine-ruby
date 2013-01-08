module Webmachine
  module Streaming
    # Implements a streaming encoder for Enumerable response bodies, such as
    # Arrays.
    # @api private
    class EnumerableEncoder < Encoder
      include Enumerable

      # Iterates over the body, encoding and yielding individual chunks
      # of the response entity.
      # @yield [chunk]
      # @yieldparam [String] chunk a chunk of the response, encoded
      def each
        body.each do |block|
          yield resource.send(encoder, resource.send(charsetter, block.to_s))
        end
      end
    end # class EnumerableEncoder
  end # module Streaming
end # module Webmachine
