require 'webmachine/configuration'
require 'webmachine/headers'
require 'webmachine/request'
require 'webmachine/response'
require 'webmachine/errors'
require 'webmachine/decision'
require 'webmachine/streaming'
require 'webmachine/adapters'
require 'webmachine/dispatcher'
require 'webmachine/application'
require 'webmachine/resource'
require 'webmachine/version'

# Webmachine is a toolkit for making well-behaved HTTP applications.
# It is based on the Erlang library of the same name.
module Webmachine
  # Starts Webmachine's default global Application serving requests
  def self.run
    application.run
  end
end
