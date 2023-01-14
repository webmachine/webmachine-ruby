require 'zlib'
require 'stringio'

module Webmachine
  class Resource
    # This module implements standard Content-Encodings that you might
    # want to use in your {Resource}.  To use one, simply return it in
    # the hash from {Callbacks#encodings_provided}.
    module Encodings
      # The 'identity' encoding, which does no compression.
      def encode_identity(data)
        data
      end

      # The 'deflate' encoding, which uses libz's DEFLATE compression.
      def encode_deflate(data)
        # The deflate options were borrowed from Rack and Mongrel1.
        Zlib::Deflate.deflate(data, Zlib::DEFAULT_COMPRESSION, -Zlib::MAX_WBITS, Zlib::DEF_MEM_LEVEL, Zlib::DEFAULT_STRATEGY)
      end

      # The 'gzip' encoding, which uses GNU Zip (via libz).
      # @note Because of the header/checksum requirements, gzip cannot
      #     be used on streamed responses.
      def encode_gzip(data)
        ''.tap do |out|
          Zlib::GzipWriter.wrap(StringIO.new(out)) { |gz| gz << data }
        end
      end
    end # module Encodings
  end # class Resource
end # module Webmachine
