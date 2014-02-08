### HEAD

* decode the value of the header 'Content-MD5' as base64-encoded string.

### 1.2.2 January 8, 2014

1.2.2 is a bugfix/patch release that expands functionality with some edge
cases, and fixes a couple of bugs. Thank you to the new contributors:
Judson Lester, John Bachir, and @bethesque!

* Added Date header to responses, it's mandatory.
* Updated RSpec options to never load DRb, since it breaks the test suite.
* Updated FSM to respond with 404 if no route matches.
* Added support for key-only extensions in content negotiation.
* Improved the README file.
* Fixed insignificance of `handle_exception` callback's return value.
* Fixed CI setup with regards to Rubinius and JRuby.
* Several smaller code cleanups.

### 1.2.1 September 28, 2013

1.2.1 is a bugfix/patch release but does introduce potentially
breaking changes in the Reel adapter. With this release, Webmachine no
longer explicitly supports Ruby 1.8.

* Updated Reel compatibility to 0.4.
* Updated Hatetepe compatibility to 0.5.2.
* Cleaned up the gemspec so bundler scripts are not included.
* Added license information to the gemspec.
* Added a link to jruby-http-kit in the README.
* Moved adapter_lint to lib/webmachine/spec so other libraries can
  test adapters that are not in the Webmachine gem.

### 1.2.0 September 7, 2013

1.2.0 is a major feature release that adds the Events instrumentation
framework, support for Websockets in Reel adapter and a bunch of bugfixes.
Added Justin McPherson and Hendrik Beskow as contributors. Thank you
for your contributions!

* Websockets support in Reel adapter.
* Added `Events` framework implementing ActiveSupport::Notifications
  instrumentation API.
* Linked mailing list and related library in README.
* Fixed operator precedence in `IOEncoder#each`.
* Fixed typo in Max-Age cookie attribute.
* Allowed attributes to be set in a `Cookie`.
* Fixed streaming in Rack adapter from Fiber that is expected
  to block
* Added a more comprehensive adapter test suite and fixed various bugs
  in the existing adapters.
* Webmachine::LazyRequestBody no longer double-buffers the request
  body and cannot be rewound.

### 1.1.0 January 12, 2013

1.1.0 is a major feature release that adds the Reel and Hatetepe
adapters, support for "weak" entity tags, streaming IO response
bodies, better error handling, a shortcut for spinning up specific
resources, and a bunch of bugfixes. Added Tony Arcieri, Sebastian
Edwards, Russell Garner, Justin McPherson, Paweł Pacana, and Nicholas
Young as contributors. Thank you for your contributions!

* Added Reel adapter.
* The trace resource now opens static files in binary mode to ensure
  compatibility on Windows.
* The trace resource uses absolute URIs for its traces.
* Added Hatetepe adapter.
* Added direct weak entity tag support.
* Related libraries are linked from the README.
* Removed some circular requires.
* Fixed documentation for the `valid_content_headers?` callback.
* Fixed `Headers` initialization by downcasing incoming header names.
* Added a `Headers#fetch` method.
* Conventionally "truthy" and "falsey" values (non-nil, non-false) can
  now be returned from callbacks that expect a boolean return value.
* Updated to the latest RSpec.
* Added support for IO response bodies (minimal).
* Moved streaming encoders to their own module for clarity.
* Added `Resource#run` that starts up a web server with default
  configuration options and the catch-all route to the resource.
* The exception handling flow was improved, clarifying the
  `handle_exception` and `finish_request` callbacks.
* Fix incompatibilities with Rack.
* The request URI will not be initialized with parts that are not
  present in the HTTP request.
* The tracing will now commit to storage after the response has been
  traced.

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
