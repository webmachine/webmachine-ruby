require 'stringio'

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
        while (chunk = body.read(CHUNK_SIZE)) && (chunk != '')
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
          each { |chunk| outstream << chunk }
        end
      end

      # Allows the response body to be converted to a IO object.
      # @return [IO,nil] the body as a IO object, or nil.
      def to_io
        IO.try_convert(body)
      end

      # Returns the length of the IO stream, if known. Returns nil if
      # the stream uses an encoder or charsetter that might modify the
      # length of the stream, or the stream size is unknown.
      # @return [Integer] the size, in bytes, of the underlying IO, or
      #   nil if unsupported
      def size
        if is_unencoded?
          if is_string_io?
            body.size
          else
            begin
              body.stat.size
            rescue SystemCallError
              # IO objects might raise an Errno if stat is unsupported.
              nil
            end
          end
        end
      end

      def empty?
        size == 0
      end

      alias_method :bytesize, :size

      private

      def can_copy_stream?
        IO.respond_to?(:copy_stream) && is_unencoded? && !is_string_io?
      end

      def is_string_io?
        StringIO === body
      end
    end # class IOEncoder
  end # module Streaming
end # module Webmachine
