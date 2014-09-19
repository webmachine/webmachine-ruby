# Routes

## Paths

```ruby
App = Webmachine::Application.new do |app|
  app.routes do
    # Will map to /orders
    add ["orders"], OrdersResource

    # Will map to /orders/:id
    # request.path_info[:id] will contain the matched token value
    add ["orders", :id], OrderResource

    # Will map to /person/:person_id/orders/:order_id and
    # provide :person_id and :order_id in the path_info
    add ["person", :person_id, "orders", :order_id], OrderResource

    # Will map to any path starting with /orders,
    # but will not provide any path_info
    add ["orders", "*"], OrderResource

    # will map to any path
    add ["*"], DefaultResource
  end
end
```

## Guards

Guards prevent a request being sent to the Resource with a matching route unless its conditions are met.

##### Lambda

```ruby
App = Webmachine::Application.new do |app|
  app.routes do
    add ["orders"], ->(request) { request.headers['X-My-App-Version'] == "1" }, OrdersResourceV1
    add ["orders"], ->(request) { request.headers['X-My-App-Version'] == "2" }, OrdersResourceV2
  end
end

```

##### Block

```ruby
App = Webmachine::Application.new do |app|
  app.routes do
    add ["orders"], OrdersResourceV1 do | request |
      request.headers['X-My-App-Version'] == "1"
    end
  end
end

```

##### Callable class

```ruby
class VersionGuard

  def initialize version
    @version = version
  end

  def call(request)
    request.headers['X-My-App-Version'] == @version
  end

end

App = Webmachine::Application.new do |app|
  app.routes do
    add ["orders"], VersionGuard.new("1"), OrdersResourceV1
    add ["orders"], VersionGuard.new("2"), OrdersResourceV2
  end
end

```