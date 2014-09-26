# Validation

There are a couple of callbacks that are the most appropriate for doing validation in. The first is the `malformed_request?` which runs early in the Finite State Machine, and the second is inside the content type handler, for example `from_json`.

## malformed_request

If `malformed_request?` returns a truthy value, then a 400 Bad Request will be returned. Unfortunately, at this early stage in the flow, we don't know what the `method` or the `Content-Type` are without inspecting the request, and this leads to some very Iffy code.

```ruby
class OrdersResource < Webmachine::Resource

  def allowed_methods
    ["POST", "GET"]
  end

  # Iffy! What method? GET doesn't require any validation.
  def malformed_request?
    if request.post?
      # What Content-Type? Very Iffy!
      if request.headers['Content-Type'] == "application/json"
        ....
      end
    else
      false
    end
  end

  def content_types_accepted
    [
      ["application/json", :from_json],
      ["application/xml", :from_xml]
    ]
  end

  def content_types_provided
    [
      ["application/json", :to_json],
      ["application/xml", :to_xml]
    ]
  end

  def post_is_create?
    true
  end

  def create_path
    "/orders/#{next_id}"
  end

  def from_json
    order = Order.from_json(request.body.to_s)
    response.body = order.save(next_id).to_json
  end

  def from_xml
    order = Order.from_xml(request.body.to_s)
    response.body = order.save(next_id).to_xml
  end

  def to_json
    Order.all.to_json
  end

  def to_xml
    Order.all.to_xml
  end

  private

  def next_id
    @next_id ||= Order.next_id
  end

end
```

## Content-Type handler

A more elegant way to handle validation is to do it in a callback where we already know the `method` and the `Content-Type` - that is, the handler for the given Content-Type (eg. `from_json` and `from_xml`). By returning a `400` from the handler, we stop the state machine flow.

```ruby
class OrdersResource < Webmachine::Resource

  def allowed_methods
    ["POST", "GET"]
  end

  # Iffy! What method? GET doesn't require any validation.
  def malformed_request?
    if request.post?
      invalid_create_order_request?
    else
      false
    end
  end

  def content_types_accepted
    [
      ["application/json", :from_json],
      ["application/xml", :from_xml]
    ]
  end

  def content_types_provided
    [
      ["application/json", :to_json],
      ["application/xml", :to_xml]
    ]
  end

  def post_is_create?
    true
  end

  def create_path
    "/orders/#{next_id}"
  end

  def from_json
    order = Order.from_json(request.body.to_s)
    # A bit less Iffy!
    return json_validation_errors(order) unless order.valid?
    response.body = order.save(next_id).to_json
  end

  # This could use some DRYing up, but you get the point.
  def from_xml
    order = Order.from_xml(request.body.to_s)
    # A bit less Iffy!
    return xml_validation_errors(order) unless order.valid?
    response.body = order.save(next_id).to_xml
  end

  def to_json
    Order.all.to_json
  end

  def to_xml
    Order.all.to_xml
  end

  private

  def json_validation_errors(order)
    response.body = order.validation_errors.to_json
    400
  end

  def xml_validation_errors(order)
    response.body = order.validation_errors.to_xml
    400
  end

  def next_id
    @next_id ||= Order.next_id
  end

end
```
