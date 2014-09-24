### Adapters

Webmachine includes adapters for [WEBrick][webrick], [Reel][reel], and
[HTTPkit][httpkit]. Additionally, the [Rack][rack] adapter lets it
run on any webserver that provides a Rack interface. It also lets it run on
[Shotgun][shotgun] ([example][shotgun_example]).

#### A Note about Rack

In order to be compatible with popular deployment stacks,
Webmachine has a [Rack](https://github.com/rack/rack) adapter (thanks to Jamis Buck).

Webmachine can be used with Rack middlware features such as Rack::Map and Rack::Cascade as long as:

1. The Webmachine app is mounted at the root directory.
2. Any requests/responses that are handled by the Webmachine app are not modified by the middleware. The behaviours that are encapsulated in Webmachine assume that no modifications
are done to requests or response outside of Webmachine.

Keep in mind that Webmachine already supports many things that Rack middleware is used for with other HTTP frameworks (eg. etags, specifying supported/preferred Accept and Content-Types).

For an example of using Webmachine with Rack middleware, see the [Pact Broker][middleware-example].

See the [Rack Adapter API docs][rack-adapter-api-docs] for more information.

#### A Note about MRI 1.9

The [Reel][reel] and [HTTPkit][httpkit]
adapters might crash with a `SystemStackError` on MRI 1.9 due to its
limited fiber stack size. If your application is affected by this, the
only known solution is to switch to JRuby, Rubinius or MRI 2.0.

[webrick]: http://rubydoc.info/stdlib/webrick
[reel]: https://github.com/celluloid/reel
[httpkit]: https://github.com/lgierth/httpkit
[rack]: https://github.com/rack/rack
[shotgun]: https://github.com/rtomayko/shotgun
[shotgun_example]: https://gist.github.com/4389220
[rack-adapter-api-docs]: http://rubydoc.info/gems/webmachine/Webmachine/Adapters/Rack
[middleware-example]: https://github.com/bethesque/pact_broker/blob/6dfa71d98e38be94f0776d30bf66cfca58f97d61/lib/pact_broker/app.rb
