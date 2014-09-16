### Application/Configurator

A call to `Webmachine::Application#configure` returns a `Webmachine::Application` instance,
so you could chain other method calls if you like. If you don't want to create your own separate
application object `Webmachine.application` will return a global one.

```ruby
require 'webmachine'
require 'my_resource'

Webmachine.application.configure do |config|
  config.ip = '127.0.0.1'
  config.port = 3000
  config.adapter = :WEBrick
end

# Start a web server to serve requests via localhost
Webmachine.application.run
```