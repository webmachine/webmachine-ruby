begin
  require 'fiber'
rescue LoadError
  require 'webmachine/fiber18'
end

module Webmachine
  # Subclasses of this class implement means for streamed/chunked
  # response bodies to be coerced to the negotiated character set and
  # encoded automatically as they are output to the client.
  # @api private
  StreamingEncoder = Struct.new(:resource, :encoder, :charsetter, :body)

  # Implements a streaming encoder for Enumerable response bodies, such as
  # Arrays.
  # @api private
  class EnumerableEncoder < StreamingEncoder
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

  # Implements a streaming encoder for IO response bodies, such as
  # File objects.
  # @api private
  class IOEncoder < StreamingEncoder
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

    # If IO#copy_stream is supported, and the charsetter and encoder
    # are noop and identity, respectively, optimize the output by
    # copying directly. Otherwise, defers to using #each.
    # @param [IO] outstream the output stream to copy the body into
    def copy_stream(outstream)
      if can_copy_stream?
        IO.copy_stream(body, outstream)
      else
        each {|chunk| outstream << chunk }
      end
    end

    # Returns the length of the IO stream, if known. Raises an
    # exception if unsupported by the underlying IO. Returns nil if
    # the stream uses an encoder or charsetter that might modify the
    # length of the stream.
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

    def is_unencoded?
      encoder.to_s == "encode_identity" &&
        charsetter.to_s == "charset_nop"
    end
  end
  # Implements a streaming encoder for callable bodies, such as
  # Proc. (essentially futures)
  # @api private
  class CallableEncoder < StreamingEncoder
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

  # Implements a streaming encoder for Fibers with the same API as the
  # EnumerableEncoder. This will resume the Fiber until it terminates
  # or returns a falsey value.
  # @api private
  class FiberEncoder < EnumerableEncoder

    # Iterates over the body by yielding to the fiber.
    # @api private
    def each
      while body.alive? && chunk = body.resume
        yield resource.send(encoder, resource.send(charsetter, chunk.to_s))
      end
    end
  end # class FiberEncoder
end # module Webmachine
