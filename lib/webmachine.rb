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
  # Starts Webmachine serving requests
  def self.run
    configure unless configuration
    Adapters.const_get(configuration.adapter).run(configuration, Dispatcher.instance)
  end
end
