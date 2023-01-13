### Adapters

Webmachine includes an adapter for [WEBrick][webrick].
Additionally, the [Rack][rack] adapter lets it
run on any webserver that provides a Rack interface. It also lets it run on
[Shotgun][shotgun] ([example][shotgun_example]).

#### A Note about Rack

In order to be compatible with popular deployment stacks,
Webmachine has a [Rack](https://github.com/rack/rack) adapter (thanks to Jamis Buck).

Webmachine can be used with Rack middlware features such as Rack::Map and Rack::Cascade as long as any requests/responses that are handled by the Webmachine app are **not** modified by the middleware. The behaviours that are encapsulated in Webmachine assume that no modifications
are done to requests or response outside of Webmachine.

Keep in mind that Webmachine already supports many things that Rack middleware is used for with other HTTP frameworks (eg. etags, specifying supported/preferred Accept and Content-Types).

The base `Webmachine::Adapters::Rack` class assumes the Webmachine application
is mounted at the route path `/` (i.e. not using `Rack::Builder#map` or Rails
`ActionDispatch::Routing::Mapper::Base#mount`). In order to
map to a subpath, use the `Webmachine::Adapters::RackMapped` adapter instead.

For an example of using Webmachine with Rack middleware, see the [Pact Broker][middleware-example].

See the [Rack Adapter API docs][rack-adapter-api-docs] for more information.

[webrick]: http://rubydoc.info/stdlib/webrick
[rack]: https://github.com/rack/rack
[shotgun]: https://github.com/rtomayko/shotgun
[shotgun_example]: https://gist.github.com/4389220
[rack-adapter-api-docs]: http://rubydoc.info/gems/webmachine/Webmachine/Adapters/Rack
[middleware-example]: https://github.com/bethesque/pact_broker/blob/6dfa71d98e38be94f0776d30bf66cfca58f97d61/lib/pact_broker/app.rb
