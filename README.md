# webmachine for Ruby [![travis](https://travis-ci.org/seancribbs/webmachine-ruby.png?branch=master)](http://travis-ci.org/seancribbs/webmachine-ruby)

webmachine-ruby is a port of
[Webmachine](https://github.com/basho/webmachine), which is written in
Erlang.  The goal of both projects is to expose interesting parts of
the HTTP protocol to your application in a declarative way.  This
means that you are less concerned with handling requests directly and
more with describing the behavior of the resources that make up your
application. Webmachine is not a web framework _per se_, but more of a
toolkit for building HTTP-friendly applications. For example, it does
not provide a templating engine or a persistence layer; those choices
are up to you.

## Features

* Handles the hard parts of content negotiation, conditional
  requests, and response codes for you.
* Most callbacks can interrupt the decision flow by returning an
  integer response code. You generally only want to do this when new
  information comes to light, requiring a modification of the response.
* Supports WEBrick and Mongrel (1.2pre+), and a Rack shim. Other host
  servers are being investigated.
* Streaming/chunked response bodies are permitted as Enumerables,
  Procs, or Fibers!
* Unlike the Erlang original, it does real Language negotiation.
* Includes the visual debugger so you can look through the decision
  graph to determine how your resources are behaving.

## Documentation & Finding Help

* [API documentation](http://rubydoc.info/gems/webmachine/frames/file/README.md)
* [Mailing list](mailto:webmachine.rb@librelist.com)
* IRC channel #webmachine on freenode

## A Note about Rack

In order to be compatible with popular deployment stacks,
Webmachine has a [Rack](https://github.com/rack/rack) adapter (thanks to Jamis Buck).
**n.b.:** We recommend that NO middleware is used. The
behaviors that are encapsulated in Webmachine assume that no modifications
are done to requests or response outside of Webmachine.

## A Note about MRI 1.9

The [Reel](https://github.com/celluloid/reel) and [Hatetepe](https://github.com/lgierth/hatetepe)
adapters might crash with a `SystemStackError` on MRI 1.9 due to its
limited fiber stack size. If your application is affected by this, the
only known solution is to switch to JRuby, Rubinius or MRI 2.0.


## Getting Started

[GiddyUp](https://github.com/basho/giddyup) is an actively
developed webmachine-ruby app that is in production. You
can look there for an example of how to write and structure a
webmachine-ruby app (although it is hacky in places).

Below we go through some examples of how to do basic things
with webmachine-ruby.

The first example defines a simple resource that doesn't demo the
true power of Webmachine but perhaps gives a feel for how a
Webmachine resource might look. `Webmachine::Resource.run` is available
to provide for quick prototyping and development. In a real application
you will want to configure what path a resource is served from.
See the __Router__ section in the README for more details on how to
do that.

There are many other HTTP features exposed to a resource through
{Webmachine::Resource::Callbacks}. A callback can alter the outcome
of the decision tree Webmachine implements, and the decision tree
is what makes Webmachine unique and powerful.

```ruby
require 'webmachine'
class MyResource < Webmachine::Resource
  def to_html
    "<html><body>Hello, world!</body></html>"
  end
end

# Start a web server to serve requests via localhost
MyResource.run
```

### Router

The router is used to map a resource to a given path. To map the class `MyResource` to
the path `/myresource` you would write something along the lines of:

```ruby
Webmachine.application.routes do
  add ['myresource'], MyResource
end

# Start a web server to serve requests via localhost
Webmachine.application.run
```

### Application/Configurator

There's a configurator that allows you to set what IP address and port
a web server should bind to as well as what web server should serve a
webmachine resource.

A call to `Webmachine::Application#configure` returns a `Webmachine::Application` instance,
so you could chain other method calls if you like. If you don't want to create your own separate
application object `Webmachine.application` will return a global one.

```ruby
require 'webmachine'
require 'my_resource'

Webmachine.application.configure do |config|
  config.ip = '127.0.0.1'
  config.port = 3000
  config.adapter = :Mongrel
end

# Start a web server to serve requests via localhost
Webmachine.application.run
```

Webmachine includes adapters for [Webrick][webrick], [Mongrel][mongrel],
[Reel][reel], and [Hatetepe][hatetepe]. Additionally, the [Rack][rack] adapter lets it
run on any webserver that provides a Rack interface. It also lets it run on
[Shotgun][shotgun] ([example][shotgun_example]).

[webrick]: http://rubydoc.info/stdlib/webrick
[mongrel]: https://github.com/evan/mongrel
[reel]: https://github.com/celluloid/reel
[hatetepe]: https://github.com/lgierth/hatetepe
[rack]: https://github.com/rack/rack
[shotgun]: https://github.com/rtomayko/shotgun
[shotgun_example]: https://gist.github.com/4389220

### Visual debugger

It can be hard to understand all of the decisions that Webmachine
makes when servicing a request to your resource, which is why we have
the "visual debugger". In development, you can turn on tracing of the
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
  # This can be any path as long as it ends with '*'
  add ['trace', '*'], Webmachine::Trace::TraceResource
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

## Related libraries

* [irwebmachine](https://github.com/robgleeson/irwebmachine) - IRB/Pry debugging of Webmachine applications
* [webmachine-test](https://github.com/bernd/webmachine-test) - Helpers for testing Webmachine applications
* [webmachine-linking](https://github.com/petejohanson/webmachine-linking) - Helpers for linking between Resources, and Web Linking
* [webmachine-sprockets](https://github.com/lgierth/webmachine-sprockets) - Integration with Sprockets assets packaging system
* [webmachine-actionview](https://github.com/rgarner/webmachine-actionview) - Integration of some Rails-style view conventions into Webmachine
* [jruby-http-kit](https://github.com/nLight/jruby-http-kit) - Includes an adapter for the Clojure-based Ring library/server

## LICENSE

webmachine-ruby is licensed under the
[Apache v2.0 license](http://www.apache.org/licenses/LICENSE-2.0). See
LICENSE for details.

