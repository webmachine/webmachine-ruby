require 'webmachine/adapters/thin/connection'

module Webmachine
  module Adapters
    module Thin
      class Backend < ::Thin::Backends::Base
        attr_reader :host, :port

        def initialize(host, port, options = {})
          @host = host
          @port = port
          super()
        end

        def connect
          @signature = EM.start_server(host, port,
                                       Webmachine::Adapters::Thin::Connection,
                                       &method(:initialize_connection))
        end

        def disconnect
          EM.stop_server(@signature)
        end

        def to_s
          "#{host}:#{port}"
        end
      end
    end
  end
end
