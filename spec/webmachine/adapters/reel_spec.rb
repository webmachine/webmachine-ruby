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
      let(:example_message) { "Hello, World!" }

      it 'supports websockets' do
        configuration.adapter_options[:websocket_handler] = proc do |socket|
          socket << example_message
        end

        reel_server(described_class.new(configuration, dispatcher)) do |client|
          parser = WebSocket::Parser.new
          parser.append client.readpartial(4096) until message = parser.next_message
          message.should eq example_message
        end
      end
    end

    def reel_server(adptr = adapter)
      thread = Thread.new { adptr.run }
      begin
        begin
          sock = TCPSocket.new(adptr.configuration.ip, adptr.configuration.port)
          begin
            sock << WebSocket::ClientHandshake.new(:get, example_url, handshake_headers).to_data

            # Discard handshake response
            # FIXME: hax
            sock.readpartial(4096)
            yield(sock)
          ensure
            sock.close
          end
        rescue Errno::ECONNREFUSED
          Thread.pass
          retry
        end
      ensure
        # FIXME: graceful shutdown would be nice
        thread.kill
      end
    end
  end
end
