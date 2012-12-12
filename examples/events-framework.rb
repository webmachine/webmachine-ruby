require 'webmachine'
require 'time'
require 'logger'

class HelloResource < Webmachine::Resource
  def to_html
    "<html><head><title>Hello from Webmachine</title></head><body>Hello, world!</body></html>\n"
  end
end

class LogListener
  def initialize
    @events = {}
  end

  def publish(*args)
  end

  def start(name, id, payload)
    @events[id] = Time.now
  end

  def finish(name, id, payload)
    time = @events.delete(id)
    request = payload[:request]
    resource = payload[:resource]
    code = payload[:code]

    puts "[%s] method=%s uri=%s code=%d resource=%s time=%s" % [
      time.iso8601, request.method, request.uri.to_s, code, resource,
      duration(time)
    ]
  end

  private

  def duration(time)
    '%.4f' % [(Time.now - time) * 1000.0]
  end
end

class StateListener
  def publish(*args); puts args.inspect; end
  def start(name, id, payload); end
  def finish(name, id, payload); end
end

Webmachine::Events.subscribe('wm.dispatch', LogListener.new)
Webmachine::Events.subscribe(/wm\.state\..+/, StateListener.new)

App = Webmachine::Application.new do |app|
  app.routes do
    add_route [], HelloResource
  end

  app.configure do |config|
    config.adapter = :WEBrick
    config.adapter_options = {:AccessLog => [], :Logger => Logger.new('/dev/null')}
  end
end

App.run
