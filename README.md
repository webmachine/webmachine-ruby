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

**NOTE**: _Webmachine is NOT compatible with Rack._ This is
intentional! Rack obscures HTTP in a way that makes it hard for
Webmachine to do its job properly, and encourages people to add
middleware that might break Webmachine's behavior. Rack is also built
on the tradition of CGI, which is nice for backwards compatibility but
also an antiquated paradigm and should be scuttled (IMHO). _Rack may
be supported in the future, but only as a shim to support other web
application servers._

## Getting Started

Webmachine is very young, but it's still easy to construct an
application for it!

```ruby
require 'webmachine'
# Require any of the files that contain your resources here
require 'my_resource' 

# Point all URIs at the MyResource class
Webmachine::Dispatcher.add_route(['*'], MyResource)

# Start the server, binds to port 3000 using WEBrick
Webmachine.run 
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
callbacks. Give them a try!

## Features

* Handles the hard parts of content negotiation, conditional
  requests, and response codes for you.
* Most callbacks can interrupt the decision flow by returning an
  integer response code. You generally only want to do this when new
  information comes to light, requiring a modification of the response.
* Currently supports WEBrick. Other host servers are planned.
* Streaming/chunked response bodies are permitted as Enumerables or Procs.

## Problems/TODOs

* Support streamed responses as Fibers.
* Configuration, command-line tools, and general polish.
* An effort has been made to make the code feel as Ruby-ish as
  possible, but there is still work to do.
* Tracing is exposed as an Array of decisions visited on the response
  object. You should be able to turn this off and on, and visualize
  the decisions on the sequence diagram.
