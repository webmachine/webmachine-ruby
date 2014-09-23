### Visual debugger

In development, you can turn on tracing of the
decision graph for a resource by implementing the `#trace?` callback
so that it returns true:

```ruby
class MyTracedResource < Webmachine::Resource
  def trace?
    true
  end

  # The rest of your callbacks...
end
```

Then enable the visual debugger resource by adding a route to your
configuration:

```ruby
Webmachine.application.routes do
  # This can be any path as long as it ends with :*
  add ['trace', :*], Webmachine::Trace::TraceResource
  # The rest of your routes...
end
```

Now when you visit your traced resource, a trace of the request
process will be recorded in memory. Open your browser to `/trace` to
list the recorded traces and inspect the result. The response from your
traced resource will also include the `X-Webmachine-Trace-Id` that you
can use to lookup the trace. It might look something like this:

![preview calls at decision](http://seancribbs-skitch.s3.amazonaws.com/Webmachine_Trace_2156885920-20120625-100153.png)

Refer to
[examples/debugger.rb](/examples/debugger.rb)
for an example of how to enable the debugger.
