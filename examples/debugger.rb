require 'webmachine'
require 'webmachine/trace'

class MyTracedResource < Webmachine::Resource
  def trace?
    true
  end

  def resource_exists?
    case request.query['e']
    when 'true'
      true
    when 'fail'
      raise 'BOOM'
    else
      false
    end
  end

  def to_html
    '<html>You found me.</html>'
  end
end

class MyTracer
  def call(name, payload)
    puts "MyTracer #{name} #{payload.inspect}"
  end
end

# Webmachine::Trace.trace_store = :pstore, "./trace"
# Webmachine::Trace.trace_listener = [Webmachine::Trace::Listener.new, MyTracer.new]

TraceExample = Webmachine::Application.new do |app|
  app.routes do
    add ['trace', :*], Webmachine::Trace::TraceResource
    add [], MyTracedResource
  end
end

TraceExample.run
