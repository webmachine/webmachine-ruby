module Webmachine
  module Streaming
    # Subclasses of this class implement means for streamed/chunked
    # response bodies to be coerced to the negotiated character set and
    # encoded automatically as they are output to the client.
    # @api private
    class Encoder
      attr_accessor :resource, :encoder, :charsetter, :body

      def initialize(resource, encoder, charsetter, body)
        @resource, @encoder, @charsetter, @body = resource, encoder, charsetter, body
      end

      protected

      # @return [true, false] whether the stream will be modified by
      # the encoder and/or charsetter. Only returns true if using the
      # built-in "encode_identity" and "charset_nop" methods.
      def is_unencoded?
        encoder.to_s == 'encode_identity' &&
          charsetter.to_s == 'charset_nop'
      end
    end # class Encoder
  end # module Streaming
end # module Webmachine
