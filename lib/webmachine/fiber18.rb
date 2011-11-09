# -*- coding: utf-8 -*-
# Poor Man's Fiber (API compatible Thread based Fiber implementation for Ruby 1.8)
# (c) 2008 Aman Gupta (tmm1)

unless defined? Fiber
  require 'thread'

  # Raised by {Fiber} when they are used improperly
  class FiberError < StandardError; end

  # Implements a reasonably-compatible Fiber class that can be used on
  # Rubies that have 1.8-style APIs.
  class Fiber
    # @yield the block that should be executed inside the Fiber
    def initialize
      raise ArgumentError, 'new Fiber requires a block' unless block_given?

      @yield = Queue.new
      @resume = Queue.new

      @thread = Thread.new{ @yield.push [ *yield(*@resume.pop) ] }
      @thread.abort_on_exception = true
      @thread[:fiber] = self
    end
    attr_reader :thread

    # Returns true if the fiber can still be resumed (or transferred
    # to). After finishing execution of the fiber block this method
    # will always return false.
    def alive?
      @thread.alive?
    end

    # Resumes the fiber from the point at which the last Fiber.yield
    # was called, or starts running it if it is the first call to
    # resume. Arguments passed to resume will be the value of the
    # Fiber.yield expression or will be passed as block parameters to
    # the fiber’s block if this is the first resume.
    #
    # Alternatively, when resume is called it evaluates to the arguments
    # passed to the next Fiber.yield statement inside the fiber’s block or
    # to the block value if it runs to completion without any Fiber.yield
    def resume *args
      raise FiberError, 'dead fiber called' unless @thread.alive?
      @resume.push(args)
      result = @yield.pop
      result.size > 1 ? result : result.first
    end

    # Yields control back to the context that resumed this fiber,
    # passing along any arguments that were passed to it. The fiber
    # will resume processing at this point when resume is called
    # next. Any arguments passed to the next resume will be the value
    # that this Fiber.yield expression evaluates to.
    # @note This method is only called internally. In your code, use
    #   {Fiber.yield}.
    def yield *args
      @yield.push(args)
      result = @resume.pop
      result.size > 1 ? result : result.first
    end

    # Yields control back to the context that resumed the fiber,
    # passing along any arguments that were passed to it. The fiber
    # will resume processing at this point when resume is called
    # next. Any arguments passed to the next resume will be the value
    # that this Fiber.yield expression evaluates to.  This will raise
    # a {FiberError} if you are not inside a {Fiber}.
    # @raise FiberError
    def self.yield *args
      raise FiberError, "can't yield from root fiber" unless fiber = Thread.current[:fiber]
      fiber.yield(*args)
    end

    # Returns the current fiber.  If you are not running in the
    # context of a fiber this method will raise a {FiberError}.
    # @raise FiberError
    def self.current
      Thread.current[:fiber] or raise FiberError, 'not inside a fiber'
    end

    # Returns a string containing a human-readable representation of
    # this Fiber.
    def inspect
      "#<#{self.class}:0x#{self.object_id.to_s(16)}>"
    end
  end
end
