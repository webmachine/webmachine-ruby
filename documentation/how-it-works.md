### How it works

* Webmachine is implemented as a Finite State Machine. The "state" that the FSM is interested in is the state of your resource. Once you've seen how to implement a resource, the best way to get an understanding of how the FSM uses that resource is to check out the [Decision Flow Diagram][diagram] and then see how it is implemented in the [Flow][flow] class.

* To create a resource, create a new class that extends Webmachine::Resource, and override the relevant callbacks to describe "facts" about your resource. For example, what content types it provides (`content_types_accepted`), what HTTP methods it supports (`allowed_methods`), whether or not it exists (`resource_exists?`), and how the resource should be rendered (`to_json`). See the [examples][examples] page for examples.

```ruby
class OrderResource < Webmachine::Resource

  def allowed_methods
    ["GET"]
  end

  def content_types_provided
    [["application/json", :to_json]]
  end

  def resource_exists?
    @order = Order.find(id)
  end

  def to_json
    @order.to_json
  end

  private

  def id
    request.path_info[:id]
  end

end
```

* To add the resource to your application, configure the route as per the [Router](/README.md#router) section in the README.

* To see a list of the callbacks that can be overriden, and documentation about how to override each one, check out the [Callbacks][callbacks] class.

* Callbacks that have a name with a question mark should return a truthy or falsey value, or an integer response code.

* Once an "end state" has been reached (for example, `resource_exists?` returns falsey to a GET request, which means a 404 response should be returned), the FSM will stop the decision flow, and return the relevant response code to the client. The implication of this is that callbacks later in the flow (eg. the method to render the resource) can rely upon the fact that the resource's existance has already been proven, that authorisation has already been checked etc. so there is no need for any `if object == nil` type boilerplate.

* Most callbacks can interrupt the decision flow by returning an integer response code. You generally only want to do this when new information comes to light, requiring a modification of the response.

### Guidelines

* A collection resource (eg. /orders) should be implemented as a separate class to a single object resource (eg. /orders/1), as the routes represent diffrent underlying objects with different "facts". For example, the orders _collection_ resource probably always exists (but may be empty), however the order with ID 1 may or may not exist.

[callbacks]: https://github.com/seancribbs/webmachine-ruby/blob/master/lib/webmachine/resource/callbacks.rb
[diagram]: http://webmachine.basho.com/images/http-headers-status-v3.png
[flow]: https://github.com/seancribbs/webmachine-ruby/blob/master/lib/webmachine/decision/flow.rb
[examples]: /documentation/examples.md
