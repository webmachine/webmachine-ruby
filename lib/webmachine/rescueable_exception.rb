module Webmachine::RescueableException
  require_relative 'errors'
  require 'set'

  UNRESCUEABLE_DEFAULTS =  [
    Webmachine::MalformedRequest,
    NoMemoryError, SystemExit, SignalException
  ].freeze

  UNRESCUEABLE = Set.new UNRESCUEABLE_DEFAULTS.dup
  private_constant :UNRESCUEABLE

  def self.===(e)
    case e
    when *UNRESCUEABLE then false
    else true
    end
  end

  #
  # Remove modifications to Webmachine::RescueableException.
  # Restores default list of unrescue-able exceptions,
  #
  # @return [nil]
  #
  def self.default!
    UNRESCUEABLE.replace Set.new(UNRESCUEABLE_DEFAULTS.dup)
    nil
  end

  #
  # @return [Array<Exception>]
  #   Returns an Array of exceptions that will not be
  #   rescued by {Webmachine::Resource#handle_exception}.
  #
  def self.unrescueables
    UNRESCUEABLE.to_a
  end

  #
  # Add a variable number of exceptions that should be rescued by
  # {Webmachine::Resource#handle_exception}. See {UNRESCUEABLE_DEFAULTS}
  # for a list of exceptions that are not caught by default.
  #
  # @param (see #remove)
  #
  def self.add(*exceptions)
    exceptions.each{|e| UNRESCUEABLE.delete(e)}
  end

  #
  # Remove a variable number ofexceptions from being rescued by
  # {Webmachine::Resource#handle_exception}. See {UNRESCUEABLE_DEFAULTS}
  # for a list of exceptions that are not caught by default.
  #
  # @param [Exception] *exceptions
  #   A subclass of Exception.
  #
  def self.remove(*exceptions)
    exceptions.each{|e| UNRESCUEABLE.add(e)}
  end
end
