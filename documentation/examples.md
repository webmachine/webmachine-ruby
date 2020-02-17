Imagine an application with an "orders" resource, `OrdersResource`, that represents the collection of orders in the application, and an "order" resource, `OrderResource`, that represents a single order object.

This is how the /orders and /orders/:id routes are mapped to their respective resource classes.

```ruby
App = Webmachine::Application.new do |app|
  app.routes do
    add ["orders"], OrdersResource
    add ["orders", :id], OrderResource
  end
end
```

# GET
* Override `resource_exists?`, `content_types_provided`, `allowed_methods`, and implement the method to render the resource.

Curious as to which order the callbacks will be invoked in? Read why it [doesn't have to matter](#callback-order).

```ruby
class OrderResource < Webmachine::Resource
  def allowed_methods
    ["GET"]
  end

  def content_types_provided
    [["application/json", :to_json]]
  end

  def resource_exists?
    order
  end

  def to_json
    order.to_json
  end

  private

  def order
    @order ||= Order.new(params)
  end

  def id
    request.path_info[:id]
  end
end

```

# POST to create a new resource in a collection
* Override `post_is_create?` to return true
* Override `create_path` to return the relative path to the new resource. Note that `create_path` will be called _before_ the content type handler (eg. `from_json`) is called, which means that you need to know the ID before the object has been inserted into the database. This might seem a hassle, but it stops you from exposing your database column IDs to the world, which is a naughty and lazy habit we've all picked up from Rails.
* The response Content-Type and status will be set for you.

```ruby
class OrdersResource < Webmachine::Resource

  def allowed_methods
    ["POST"]
  end

  def content_types_accepted
    [["application/json", :from_json]]
  end

  def post_is_create?
    true
  end

  def create_path
    "/orders/#{next_id}"
  end

  private

  def from_json
    response.body = new_order.save(next_id).to_json
  end

  def next_id
    @id ||= Order.next_id
  end

  def new_order
    @new_order ||= Order.new(params)
  end

  def params
    JSON.parse(request.body.to_s)
  end
end
```

# POST to perform a task
* Override `allowed_methods`, `process_post`, and `content_types_provided` (if the response has a content type).
* Rather than providing a method handler in the `content_type_provided` mappings, put all the code to be executed in `process_post`.
* `process_post` must return true, or the HTTP response code.

```ruby
class DispatchOrderResource < Webmachine::Resource
  def content_types_provided
    [["application/json"]]
  end

  def allowed_methods
    ["POST"]
  end

  def resource_exists?
    @order = Order.find(id)
  end

  def process_post
    @order.dispatch(params['some_param'])
    response.body = { message: "Successfully dispatched order #{id}" }.to_json
    true
  end

  private

  def id
    request.path_info[:id]
  end

  def params
    JSON.parse(request.body.to_s)
  end
end

```

# PUT
* Override `resource_exists?`, `content_types_accepted`, `allowed_methods`, and implement the method to create/replace the resource.

```ruby
class OrderResource < Webmachine::Resource

  def allowed_methods
    ["PUT"]
  end

  def content_types_accepted
    [["application/json", :from_json]]
  end

  # Note that returning falsey will NOT result in a 404 for PUT requests.
  # See note below.
  def resource_exists?
    order
  end

  def from_json
    # Remember PUT should replace the entire resource, not merge the attributes! That's what PATCH is for.
    # It's also why you should not expose your database IDs as your API IDs.
    order.destroy if order
    new_order = Order.new(params)
    new_order.save(id)
    response.body = new_order.to_json
  end

  private

  def order
    @order ||= Order.find(id)
  end

  def params
    JSON.parse(request.body.to_s)
  end

  def id
    request.path_info[:id]
  end
end
```

If you wish to disallow PUT to a non-existent resource, read more [here](https://github.com/webmachine/webmachine-ruby/issues/207#issuecomment-132604379).

# PATCH
* Webmachine does not currently support PATCH requests. See https://github.com/webmachine/webmachine-ruby/issues/109 for more information and https://github.com/bethesque/pact_broker/blob/2918814e70bbda14df68598a6a41502a5eac4308/lib/pact_broker/api/resources/pacticipant.rb for a dirty hack to make it work if you need to.

# DELETE
* Override `resource_exists?` and `delete_resource`
* `delete_resource` must return true
* See callbacks.rb for documentation on asynchronous deletes.

```ruby
class OrderResource < Webmachine::Resource

  def allowed_methods
    ["DELETE"]
  end

  def resource_exists?
    order
  end

  def delete_resource
    order.destroy
    true
  end

  private

  def order
    @order ||= Order.find(id)
  end

  def id
    request.path_info[:id]
  end

end
```

Thanks to [oestrich][oestrich] for putting together the original example. You can see the full source code [here][source].

[oestrich]: https://github.com/oestrich
[source]: https://gist.github.com/oestrich/3638605

<a name="callback-order"></a>
## What order are the callbacks invoked in?

This question is actually irrelevant if you write your code in a "stateless" way using lazy initialization as the examples do above. As much as possible, think about exposing "facts" about your resource, not writing procedural code that needs to be called in a certain order. See [How it works](/documentation/how-it-works.md) for more information on how the Webmachine state machine works.
