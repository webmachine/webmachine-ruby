module Webmachine
  module Adapters
    module Thin
      class Connection < EM::Connection
        include ::Thin::Logging

        attr_accessor :app, :backend, :request, :response
        attr_writer :threaded

        def post_init
          @request = ::Thin::Request.new
          @response = ::Thin::Response.new
        end

        def receive_data(data)
          trace { data }

          if request.parse(data)
            if threaded?
              request.threaded = true
              EM.defer(method(:process))
            else
              request.threaded = false
              process
            end
          end
        rescue ::Thin::InvalidRequest => e
          log "!! Invalid request"
          log_error e
          close_connection
        end

        def process
          # Add client info to the request env
          request.remote_address = remote_address

          app.call(request, response)

          # Make the response persistent if requested by the client
          response.persistent! if request.persistent?

          # Send the response
          response.each do |chunk|
            trace { chunk }
            send_data chunk
          end
        rescue Exception => e
          handle_error(e)
          puts e.backtrace
        ensure
          terminate_request
        end

        # Logs catched exception and closes the connection.
        def handle_error(e)
          log "!! Unexpected error while processing request: #{$!.message}"
          log_error(e)
          close_connection rescue nil
        end

        def close_request_response
          request.close  rescue nil
          response.close rescue nil
        end

        # Does request and response cleanup (closes open IO streams and
        # deletes created temporary files).
        # Re-initializes response and request if client supports persistent
        # connection.
        def terminate_request
          unless persistent?
            close_connection_after_writing rescue nil
            close_request_response
          else
            close_request_response
            # Prepare the connection for another request if the client
            # supports HTTP pipelining (persistent connection).
            post_init
          end
        end

        # Called when the connection is unbinded from the socket
        # and can no longer be used to process requests.
        def unbind
          response.body.fail if response.body.respond_to?(:fail)
          backend.connection_finished(self)
        end

        # Allows this connection to be persistent.
        def can_persist!
          @can_persist = true
        end

        # Return +true+ if this connection is allowed to stay open and be persistent.
        def can_persist?
          @can_persist
        end

        # Return +true+ if the connection must be left open
        # and ready to be reused for another request.
        def persistent?
          @can_persist && response.persistent?
        end

        # +true+ if <tt>app.call</tt> will be called inside a thread.
        # You can set all requests as threaded setting <tt>Connection#threaded=true</tt>
        # or on a per-request case returning +true+ in <tt>app.deferred?</tt>.
        def threaded?
          @threaded || (app.respond_to?(:deferred?) && app.deferred?(request.env))
        end

        # IP Address of the remote client.
        def remote_address
          socket_address
        rescue Exception
          log_error
          nil
        end

        protected
          # Returns IP address of peer as a string.
          def socket_address
            Socket.unpack_sockaddr_in(get_peername)[1]
          end
      end
    end
  end
end
