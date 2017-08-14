### How it works

Unlike frameworks like Grape and Sinatra, which create a response by running a predefined procedure when a request is received, Webmachine creates an HTTP response by determining a series of "facts" about the resource.

Webmachine is implemented as a [Finite State Machine][diagram]. It uses the facts about your resource to determine the flow though the FSM in order to produce a response.

As an example, imagine the following request:

    $ curl  "http://example.org/widgets/1" -H "Accept: application/json" -u jsmith -p secret

The series of "facts" that Webmachine will determine as it moves through the state machine for this request include:

  * Does the route /widgets/:id exist?
  * Does a widget with ID 1 exist?
  * Is jsmith with the given password allowed to execute this HTTP method on this widget?
  * Can the GET method be called for a widget?
  * Can a widget be rendered as application/json?

If the answer to each of these questions is "yes", then Webmachine will ask the final question - please render the response for me. If the answer to any of the questions along the way is "no", then the appropriate HTTP response code will be returned automatically.

## Creating a resource

* The way you tell Webmachine the facts about your resource is to create a class that extends Webmachine::Resource, and override the relevant callbacks. For example, what content types it provides (`content_types_accepted`), what HTTP methods it supports (`allowed_methods`), whether or not it exists (`resource_exists?`), and how the resource should be rendered (`to_json`). See the [examples][examples] page for examples of how to implement support for each HTTP method.

```ruby
class WidgetResource < Webmachine::Resource

  def allowed_methods
    ["GET"]
  end

  def content_types_provided
    [["application/json", :to_json]]
  end

  def resource_exists?
    widget # Truthy or falsey
  end

  def to_json
    widget.to_json
  end

  private

  def widget
    @widget ||= Widget.find(id)
  end

  def id
    request.path_info[:id]
  end

end
```

* To see a list of the callbacks that can be overridden, and documentation about how to override each one, check out the [Callbacks][callbacks] class.

* Callbacks that have a name with a question mark should return a truthy or falsey value, or an integer response code.

* Most callbacks can interrupt the decision flow by returning an integer response code. You generally only want to do this when new information comes to light, requiring a modification of the response.

* Once an "end state" has been reached (for example, `resource_exists?` returns falsey to a GET request, or a callback returns an explicit response code), the FSM will stop the decision flow, and return the relevant response code to the client. The implication of this is that callbacks later in the flow (eg. the method to render the resource) can rely upon the fact that the resource's existence has already been proven, that authorisation has already been checked etc. so there is no need for any `if object == nil` type boilerplate.

### Advanced

* Once you've seen how to implement a resource, the best way to get an understanding of how the FSM uses that resource is to check out the [Decision Flow Diagram][diagram] and then see how it is implemented in the [Flow][flow] class.

### Guidelines

* A collection resource (eg. /orders) should be implemented as a separate class to a single object resource (eg. /orders/1), as the routes represent different underlying objects with different "facts". For example, the orders _collection_ resource probably always exists (but may be empty), however the order with ID 1 may or may not exist.

[callbacks]: https://github.com/seancribbs/webmachine-ruby/blob/master/lib/webmachine/resource/callbacks.rb
[diagram]: https://webmachine.github.io/images/http-headers-status-v3.png
[flow]: https://github.com/seancribbs/webmachine-ruby/blob/master/lib/webmachine/decision/flow.rb
[examples]: /documentation/examples.md
