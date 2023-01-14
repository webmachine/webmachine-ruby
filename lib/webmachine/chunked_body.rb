require 'webmachine/constants'

module Webmachine
  # {ChunkedBody} is used to wrap an {Enumerable} object (like an enumerable
  # {Response#body}) so it yields proper chunks for chunked transfer encoding.
  #
  #     case response.body
  #     when String
  #       socket.write(response.body)
  #     when Enumerable
  #       Webmachine::ChunkedBody.new(response.body).each do |chunk|
  #         socket.write(chunk)
  #       end
  #     end
  #
  # This is needed for Ruby webservers which don't do the chunking themselves.
  class ChunkedBody
    # Final chunk in any chunked-encoding response
    FINAL_CHUNK = "0#{CRLF}#{CRLF}".freeze

    # Creates a new {ChunkedBody} from the given {Enumerable}.
    # @param [Enumerable] body the enumerable response body
    # @return [ChunkedBody] the wrapped response body
    def initialize(body)
      @body = body
    end

    # Calls the given block once for each chunk, passing that chunk as a
    # parameter.
    # Returns an {Enumerator} if no block is given.
    def each
      return to_enum unless block_given?

      @body.each do |chunk|
        size = chunk.bytesize
        next if size == 0
        yield([size.to_s(16), CRLF, chunk, CRLF].join)
      end
      yield(FINAL_CHUNK)
    end
  end # class ChunkedBody
end # module Webmachine
