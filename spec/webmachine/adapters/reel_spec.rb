require 'spec_helper'

if RUBY_VERSION >= "1.9"
  describe Webmachine::Adapters::Reel do
    let(:configuration) { Webmachine::Configuration.default }
    let(:dispatcher) { Webmachine::Dispatcher.new }
    let(:adapter) do
      described_class.new(configuration, dispatcher)
    end

    it 'inherits from Webmachine::Adapter' do
      adapter.should be_a_kind_of(Webmachine::Adapter)
    end

    it 'implements #run' do
      adapter.should respond_to(:run)
    end

    it 'implements #process' do
      adapter.should respond_to(:process)
    end

    context 'websockets' do
      let(:configuration) do
        config = Webmachine::Configuration.default

        # FIXME: It seems existing specs leave another server running
        config.port += 1
        config
      end
      let(:example_host)    { "www.example.com" }
      let(:example_path)    { "/example"}
      let(:example_url)     { "ws://#{example_host}#{example_path}" }
      let :handshake_headers do
        {
          "Host"                   => example_host,
          "Upgrade"                => "websocket",
          "Connection"             => "Upgrade",
          "Sec-WebSocket-Key"      => "dGhlIHNhbXBsZSBub25jZQ==",
          "Origin"                 => "http://example.com",
          "Sec-WebSocket-Protocol" => "chat, superchat",
          "Sec-WebSocket-Version"  => "13"
        }
      end
      let(:client_message) { "Hi server!" }
      let(:server_message) { "Hi client!" }

      it 'supports websockets' do
        configuration.adapter_options[:websocket_handler] = proc do |socket|
          socket.read.should eq client_message
          socket << server_message
        end

        reel_server(described_class.new(configuration, dispatcher)) do |client|
          client << WebSocket::ClientHandshake.new(:get, example_url, handshake_headers).to_data
          
          # Discard handshake response
          # FIXME: hax
          client.readpartial(4096)

          client << WebSocket::Message.new(client_message).to_data
          parser = WebSocket::Parser.new
          parser.append client.readpartial(4096) until message = parser.next_message

          message.should eq server_message
        end
      end
    end

    def reel_server(adptr = adapter)
      thread = Thread.new { adptr.run }
      begin
        timeout(5) do
          begin
            sock = TCPSocket.new(adptr.configuration.ip, adptr.configuration.port)
            begin
              yield(sock)
            ensure
              sock.close
            end
          rescue Errno::ECONNREFUSED
            Thread.pass
            retry
          end
        end
      ensure
        # FIXME: graceful shutdown would be nice
        thread.kill
      end
    end
  end
end
