# webmachine for Ruby
 [![Gem Version](https://badge.fury.io/rb/webmachine.svg)](https://badge.fury.io/rb/webmachine)
 [![Build Status](https://github.com/webmachine/webmachine-ruby/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/webmachine/webmachine-ruby/actions/workflows/test.yml)

webmachine-ruby is a port of
[Webmachine](https://github.com/basho/webmachine), which is written in
Erlang.  The goal of both projects is to expose interesting parts of
the HTTP protocol to your application in a declarative way.  This
means that you are less concerned with the procedures involved in handling
requests directly and more with describing facts about the resources
that make up your application.
Webmachine is not a web framework _per se_, but more of a
toolkit for building HTTP-friendly applications. For example, it does
not provide a templating engine or a persistence layer; those choices
are up to you.

## Features

* Handles the hard parts of content negotiation, conditional
  requests, and response codes for you.
* Provides a base resource with points of extension to let you
  describe what is relevant about your particular resource.
* Supports WEBrick and a Rack shim. Other host servers are being investigated.
* Streaming/chunked response bodies are permitted as Enumerables,
  Procs, or Fibers!
* Unlike the Erlang original, it does real Language negotiation.
* Includes a visual debugger so you can look through the decision
  graph to determine how your resources are behaving.

## Documentation & Finding Help

* [How it works](/documentation/how-it-works.md) - understand how Webmachine works and the basics of creating a resource.
* [Example resources][example-resources] showing how to implement each HTTP method.
* [Routes][routes]
* [Authentication and authorization][authentication-and-authorization]
* [Validation][validation]
* [Error handling][error-handling]
* [Visual debugger][visual-debugger]
* [Configurator][configurator]
* [Webserver adapters][adapters]
* [Versioning APIs][versioning-apis]
* [API documentation](http://rubydoc.info/gems/webmachine/frames/file/README.md)
* [Mailing list](mailto:webmachine.rb@librelist.com)
* IRC channel #webmachine on freenode

## Getting Started

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

### A simple static  HTML resource

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

### A simple dynamic JSON Resource

```ruby
require 'webmachine'
require 'widget'

class MyResource < Webmachine::Resource

  # GET and HEAD are allowed by default, but are shown here for clarity.
  def allowed_methods
    ['GET','HEAD']
  end

  def content_types_provided
    [['application/json', :to_json]]
  end

  # Return a Truthy or Falsey value
  def resource_exists?
    widget
  end

  def widget
    @widget ||= Widget.find(request.path_info[:id])
  end

  def to_json
    widget.to_json
  end
end

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

When the resource needs to be mapped with variables that will be passed into the resource, use symbols to identify which path components are variables.

```ruby

Webmachine.application.routes do
  add ['myresource', :id], MyResource
end

```

To add more components to the URL mapping, simply add them to the array.

```ruby

Webmachine.application.routes do
  add ['myparentresource', :parent_id, 'myresource', :id], MyResource
end

```

Read more about routing [here][routes].

### Application/Configurator

There is a configurator that allows you to set what IP address and port
a web server should bind to as well as what web server should serve a
webmachine resource. Learn how to configure your application [here][configurator].


### Adapters

Webmachine provides adapters for many popular webservers. Learn more [here][adapters].

### Visual debugger

It can be hard to understand all of the decisions that Webmachine
makes when servicing a request to your resource, which is why we have
the "visual debugger". Learn how to configure it [here][visual-debugger].

## Related libraries

* [webmachine-test](https://github.com/bernd/webmachine-test) - Helpers for testing Webmachine applications
* [webmachine-linking](https://github.com/petejohanson/webmachine-linking) - Helpers for linking between Resources, and Web Linking
* [webmachine-actionview](https://github.com/rgarner/webmachine-actionview) - Integration of some Rails-style view conventions into Webmachine
* [jruby-http-kit](https://github.com/nLight/jruby-http-kit) - Includes an adapter for the Clojure-based Ring library/server
* [newrelic-webmachine](https://github.com/mdub/newrelic-webmachine) - NewRelic instrumentation

## LICENSE

webmachine-ruby is licensed under the
[Apache v2.0 license](http://www.apache.org/licenses/LICENSE-2.0). See
LICENSE for details.

[example-resources]: /documentation/examples.md
[versioning-apis]: /documentation/versioning-apis.md
[routes]: /documentation/routes.md
[error-handling]: /documentation/error-handling.md
[authentication-and-authorization]: /documentation/authentication-and-authorization.md
[adapters]: /documentation/adapters.md
[visual-debugger]: /documentation/visual-debugger.md
[configurator]: /documentation/configurator.md
[validation]: /documentation/validation.md
