require 'webmachine/adapters/webrick'

module Webmachine
  # Contains classes and modules that connect Webmachine to Ruby
  # application servers.
  module Adapters
  end

  class << self
    # @return [Symbol] the current webserver adapter
    attr_accessor :adapter
  end

  self.adapter = :WEBrick
end
