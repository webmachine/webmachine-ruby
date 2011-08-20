module Webmachine
  class StreamingEncoder
    def initialize(resource, encoder, charsetter, body)
      @resource, @encoder, @charsetter, @body = resource, encoder, charsetter, body
    end
  end

  class EnumerableEncoder < StreamingEncoder
    include Enumerable

    def each
      body.each do |block|
        yield @resource.send(@encoder, resource.send(@charsetter, block))
      end
    end
  end

  class CallableEncoder < StreamingEncoder
    def call
      @resource.send(@encoder, @resource.send(@charsetter, body.call))
    end

    def to_proc
      method(:call).to_proc
    end
  end
end
