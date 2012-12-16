module Webmachine
  module Streaming
    # Implements a streaming encoder for IO response bodies, such as
    # File objects.
    # @api private
    class IOEncoder < Encoder
      include Enumerable
      CHUNK_SIZE = 8192
      # Iterates over the IO, encoding and yielding individual chunks
      # of the response entity.
      # @yield [chunk]
      # @yieldparam [String] chunk a chunk of the response, encoded
      def each
        while chunk = body.read(CHUNK_SIZE) && chunk != ""
          yield resource.send(encoder, resource.send(charsetter, chunk))
        end
      end

      # If IO#copy_stream is supported, and the stream is unencoded,
      # optimize the output by copying directly. Otherwise, defers to
      # using #each.
      # @param [IO] outstream the output stream to copy the body into
      def copy_stream(outstream)
        if can_copy_stream?
          IO.copy_stream(body, outstream)
        else
          each {|chunk| outstream << chunk }
        end
      end

      # Returns the length of the IO stream, if known. Raises an
      # exception if #stat is unsupported by the underlying IO.
      # Returns nil if the stream uses an encoder or charsetter that
      # might modify the length of the stream.
      # @return [Fixnum] the size, in bytes, of the underlying IO
      def size
        if is_unencoded?
          body.stat.size
        else
          nil
        end
      end

      alias bytesize size

      private
      def can_copy_stream?
        IO.respond_to?(:copy_stream) && is_unencoded?
      end
    end # class IOEncoder
  end # module Streaming
end # module Webmachine
