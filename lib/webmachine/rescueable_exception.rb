module Webmachine::RescuableException
  require_relative 'errors'
  require 'set'

  UNRESCUABLE_DEFAULTS = [
    Webmachine::MalformedRequest,
    NoMemoryError, SystemExit, SignalException
  ].freeze

  UNRESCUABLE = Set.new UNRESCUABLE_DEFAULTS.dup
  private_constant :UNRESCUABLE

  def self.===(e)
    case e
    when *UNRESCUABLE then false
    else true
    end
  end

  #
  # Remove modifications to Webmachine::RescuableException.
  # Restores default list of unrescue-able exceptions.
  #
  # @return [nil]
  #
  def self.default!
    UNRESCUABLE.replace Set.new(UNRESCUABLE_DEFAULTS.dup)
    nil
  end

  #
  # @return [Array<Exception>]
  #   Returns an Array of exceptions that will not be
  #   rescued by {Webmachine::Resource#handle_exception}.
  #
  def self.UNRESCUABLEs
    UNRESCUABLE.to_a
  end

  #
  # Add a variable number of exceptions that should be rescued by
  # {Webmachine::Resource#handle_exception}. See {UNRESCUABLE_DEFAULTS}
  # for a list of exceptions that are not caught by default.
  #
  # @param (see #remove)
  #
  def self.add(*exceptions)
    exceptions.each { |e| UNRESCUABLE.delete(e) }
  end

  #
  # Remove a variable number of exceptions from being rescued by
  # {Webmachine::Resource#handle_exception}. See {UNRESCUABLE_DEFAULTS}
  # for a list of exceptions that are not caught by default.
  #
  # @param [Exception] *exceptions
  #   A subclass of Exception.
  #
  def self.remove(*exceptions)
    exceptions.each { |e| UNRESCUABLE.add(e) }
  end
end
