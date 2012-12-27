# webmachine for Ruby [![travis](https://secure.travis-ci.org/seancribbs/webmachine-ruby.png)](http://travis-ci.org/seancribbs/webmachine-ruby)

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

## A Note about Rack

Webmachine has a Rack adapter -- thanks to Jamis Buck -- but when
using it, we recommend you ensure that NO middleware is used.  The
behaviors that are encapsulated in Webmachine could be broken by
middlewares that sit above it, and there is no way to detect them at
runtime. _Caveat implementor_. That said, Webmachine should behave properly
when given a clear stack.

## Getting Started

Webmachine is very young, but it's still easy to construct an
application for it!

```ruby
require 'webmachine'
# Require any of the files that contain your resources here
require 'my_resource'

# Create an application which encompasses routes and configruation
MyApp = Webmachine::Application.new do |app|
  app.routes do
    # Point all URIs at the MyResource class
    add ['*'], MyResource
  end
end

# Start the server, binds to port 8080 using WEBrick
MyApp.run
```

Your resource will look something like this:

```ruby
class MyResource < Webmachine::Resource
  def to_html
    "<html><body>Hello, world!</body></html>"
  end
end
```

Run the first file and your application is up. That's all there is to
it! If you want to customize your resource more, look at the available
callbacks in lib/webmachine/resource/callbacks.rb. For example, you
might want to enable "gzip" compression on your resource, for which
you can simply add an `encodings_provided` callback method:

```ruby
class MyResource < Webmachine::Resource
  def encodings_provided
    {"gzip" => :encode_gzip, "identity" => :encode_identity}
  end

  def to_html
    "<html><body>Hello, world!</body></html>"
  end
end
```

There are many other HTTP features exposed to your resource through
{Webmachine::Resource::Callbacks}. Give them a try!

### Application/Configurator

There's a configurator that allows you to set the ip address and port
bindings as well as a different webserver adapter.  You can also add
your routes in a block (as shown above). Both of these call return the
`Webmachine::Application` instance, so you could chain them if you
like. If you don't want to create your own separate application
object, `Webmachine.application` will return a global one.

```ruby
require 'webmachine'
require 'my_resource'

Webmachine.application.routes do
  add ['*'], MyResource
end

Webmachine.application.configure do |config|
  config.ip = '127.0.0.1'
  config.port = 3000
  config.adapter = :Mongrel
end

# Start the server.
Webmachine.application.run
```

Webmachine includes adapters for [Webrick][webrick], [Mongrel][mongrel],
[Reel][reel], and [Hatetepe]. Additionally, the [Rack][rack] adapter lets it
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
[examples/debugger.rb](/seancribbs/webmachine-ruby/blob/master/examples/debugger.rb)
for an example of how to enable the debugger.

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

## Caveats

* The [Reel](https://github.com/celluloid/reel) adapter might fail with a
  `SystemStackError` on MRI (< 2.0) due to its limited fiber stack size.
  The only known solution is to switch to JRuby, Rubinius or MRI 2.0.

## Problems/TODOs

* Command-line tools, and general polish.

## Documentation & Finding Help

* [API documentation](http://rubydoc.info/gems/webmachine/frames/file/README.md)
* IRC channel #webmachine on freenode

## Related libraries

* [irwebmachine](https://github.com/generalassembly/irwebmachine) - IRB/Pry debugging of Webmachine applications
* [webmachine-test](https://github.com/bernd/webmachine-test) - Helpers for testing Webmachine applications
- [webmachine-linking](https://github.com/petejohanson/webmachine-linking) - Helpers for linking between Resources, and Web Linking
- [webmachine-sprockets](https://github.com/lgierth/webmachine-sprockets) - Integration with Sprockets assets packaging system

## LICENSE

webmachine-ruby is licensed under the
[Apache v2.0 license](http://www.apache.org/licenses/LICENSE-2.0). See
LICENSE for details.

## Changelog

### 1.0.0 July 7, 2012

1.0.0 is a major feature release that finally includes the visual
debugger, some nice cookie support, and some new extension
points. Added Peter Johanson and Armin Joellenbeck as
contributors. Thank you for your contributions!

* A cookie parsing and manipulation API was added.
* Conneg headers now accept any amount of whitespace around commas,
  including none.
* `Callbacks#handle_exception` was added so that resources can handle
  exceptions that they generate and produce more friendly responses.
* Chunked and non-chunked response bodies in the Rack adapter were
  fixed.
* The WEBrick example was updated to use the new API.
* `Dispatcher` was refactored so that you can modify how resources
  are initialized before dispatching occurs.
* `Route` now includes the `Translation` module so that exception
  messages are properly rendered.
* The visual debugger was added (more details in the README).
* The `Content-Length` header will always be set inside Webmachine and
  is no longer reliant on the adapter to set it.

### 0.4.2 March 22, 2012

0.4.2 is a bugfix release that corrects a few minor issues. Added Lars
Gierth and Rob Gleeson as contributors. Thank you for your
contributions!

* I always intended for Webmachine-Ruby to be Apache licensed, but now
  that is explicit.
* When the `#process_post` callback returns an invalid value, that
  will now be `inspect`ed in the raised exception's message.
* Route bindings are now applied to the `Request` object before the
  `Resource` class is instantiated. This means you can inspect them
  inside the `#initialize` method of your resource.
* Some `NameError` exceptions and scope problems in the Mongrel
  adapter were resolved.
* URL-encoded `=` characters in the query string decoded in the proper
  order.

### 0.4.1 February 8, 2012

0.4.1 is a bugfix release that corrects a few minor issues. Added Sam
Goldman as a contributor. Thank you for your contributions!

* Updated README with `Webmachine::Application` examples.
* The CGI env vars `CONTENT_LENGTH` and `CONTENT_TYPE` are now being
  correctly converted into their Webmachine equivalents.
* The request body given via the Rack and Mongrel adapters now
  responds to `#to_s` and `#each` so it can be treated like a `String`
  or `Enumerable` that yields chunks.

### 0.4.0 February 5, 2012

0.4.0 includes some important refactorings, isolating the idea of
global state into an Application object with its own Dispatcher and
configuration, and making Adapters into real classes with a consistent
interface. It also adds some query methods on the Request object for
the HTTP method and scheme and Route guards (matching predicates).
Added Michael Maltese, Emmanuel Gomez, and Bernerd Schaefer as
committers. Thank you for your contributions!

* Fixed `Request#query` to handle nil values for the URI query accessor.
* `Webmachine::Dispatcher` is a real class rather than a module with
  state.
* `Webmachine::Application` is a class that includes its own
  dispatcher and configuration. The default instance is accessible via
  `Webmachine.application`.
* `Webmachine::Adapter` is now the superclass of all implemented
  adapters so that they have a uniform interface.
* The Mongrel spec is skipped on JRuby since version 1.2 (pre-release)
  doesn't work. Direct Mongrel support may be removed in a later
  release.
* `Webmachine::Dispatcher::Route` now accepts guards, which may be
  expressed as lambdas/procs or any object responding to `call`
  preceding the `Resource` class in the route definition, or as a
  trailing block. All guards will be passed the `Request` object when
  matching the route and should return a truthy or falsey value
  (without side-effects).

### 0.3.0 November 9, 2011

0.3.0 introduces some new features, refactorings, and now has 100%
documentation coverage! Among the new features are minimal Rack
compatibility, streaming responses via Fibers and a friendlier route
definition syntax. Added Jamis Buck as a committer. Thank you for your
contributions!

* Chunked bodies are now wrapped in a way that works on webservers
  that don't automatically produce them.
* HTTP Basic Authentication is easy to add to resources, just include
  `Webmachine::Resource::Authentication`.
* Routes are a little less painful to add, you can now specify them
  with `Webmachine.routes` which will be evaled into the `Dispatcher`.
* The new default port is 8080.
* Rack is minimally supported as a host server. _Don't put middleware
  above Webmachine!_
* Fibers can be used as streamed response bodies.
* `Dispatcher#add_route` will now return the added `Route` instance.
* The header-conversion code for CGI-style servers has been extracted
  into `Webmachine::Headers`.
* `Route#path_spec` is now public so that applications can inspect
  existing routes, perhaps for URL generation.
* `Request#query` now uses `CGI.unescape` so '+' characters are
  correctly parsed.
* YARD documentation has 100% coverage.

### 0.2.0 September 11, 2011

0.2.0 includes an adapter for Mongrel and a central place for
configuration as well as numerous bugfixes. Added Ian Plosker and
Bernd Ahlers as committers. Thank you for your contributions!

* Acceptable media types are matched less strictly, which has
  implications on both responses and PUT requests. See the
  [discussion on the commit](https://github.com/seancribbs/webmachine-ruby/commit/3686d0d9ff77fc98aff59f89478e9c6c18844ca1).
* Resources now receive a callback after the language has been
  negotiated, so they can decide what to do with it.
* Added `Webmachine::Configuration` so we can more easily support more
  than one host server/adapter.
* Added Mongrel adapter, supporting 1.2pre+.
* Media type headers are more lax about whitespace following
  semicolons.
* Fix some problems with callable response bodies.
* Make sure String response bodies get a Content-Length header added
  and streaming responses get chunked encoding.
* Numerous refactorings, including extracting `MediaType` into its own
  top-level class.

### 0.1.0 August 25, 2011

This is the initial release. Most things work, but only WEBrick is supported.
