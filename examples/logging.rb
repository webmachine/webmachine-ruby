require 'webmachine'
require 'time'
require 'logger'

class HelloResource < Webmachine::Resource
  def to_html
    "<html><head><title>Hello from Webmachine</title></head><body>Hello, world!</body></html>\n"
  end
end

class LogListener
  def call(*args)
    handle_event(Webmachine::Events::InstrumentedEvent.new(*args))
  end

  def handle_event(event)
    request = event.payload[:request]
    resource = event.payload[:resource]
    code = event.payload[:code]

    puts '[%s] method=%s uri=%s code=%d resource=%s time=%.4f' % [
      Time.now.iso8601, request.method, request.uri.to_s, code, resource,
      event.duration
    ]
  end
end

Webmachine::Events.subscribe('wm.dispatch', LogListener.new)

App = Webmachine::Application.new do |app|
  app.routes do
    add_route [], HelloResource
  end

  app.configure do |config|
    config.adapter = :WEBrick
    config.adapter_options = {AccessLog: [], Logger: Logger.new('/dev/null')}
  end
end

App.run
