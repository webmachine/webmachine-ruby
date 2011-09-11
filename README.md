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
* Supports WEBrick and Mongrel (1.2pre+). Other host servers are being
  investigated.
* Streaming/chunked response bodies are permitted as Enumerables or Procs.
* Unlike the Erlang original, it does real Language negotiation.

## Problems/TODOs

* Support streamed responses as Fibers.
* Command-line tools, and general polish.
* Tracing is exposed as an Array of decisions visited on the response
  object. You should be able to turn this off and on, and visualize
  the decisions on the sequence diagram.

## Changelog

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
