### Adapters

Webmachine includes adapters for [WEBrick][webrick], [Reel][reel], and
[HTTPkit][httpkit]. Additionally, the [Rack][rack] adapter lets it
run on any webserver that provides a Rack interface. It also lets it run on
[Shotgun][shotgun] ([example][shotgun_example]).

#### A Note about Rack

In order to be compatible with popular deployment stacks,
Webmachine has a [Rack](https://github.com/rack/rack) adapter (thanks to Jamis Buck).
**n.b.:** We recommend that NO middleware is used. The
behaviors that are encapsulated in Webmachine assume that no modifications
are done to requests or response outside of Webmachine.

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