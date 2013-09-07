require 'webmachine/adapters/lazy_request_body'
require 'webmachine/adapters/webrick'

module Webmachine
  # Contains classes and modules that connect Webmachine to Ruby
  # application servers.
  module Adapters
    autoload :Mongrel,  'webmachine/adapters/mongrel'
    autoload :Reel,     'webmachine/adapters/reel'
    autoload :Hatetepe, 'webmachine/adapters/hatetepe'
  end
end
