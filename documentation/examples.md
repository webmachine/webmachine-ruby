Imagine an application with an "orders" resource that represents the collection of orders in the application, and an "order" resource that represents a single order object.

```ruby
App = Webmachine::Application.new do |app|
  app.routes do
    add ["orders"], OrdersResource
    add ["orders", :id], OrderResource
    add ['trace', '*'], Webmachine::Trace::TraceResource
  end
end
```

# GET
* Override `resource_exists?`, `content_types_provided`, `allowed_methods`, and implement the method to render the resource.

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

# POST to create a new resource in a collection
* Override `post_is_create?` to return true
* Override `create_path` to return the relative path to the new resource. Note that this will be called _before_ the resource is actually created, which means that you need to know the ID before the object has been inserted into the database. This might seem a hassle, but it stops you from exposing your database column IDs to the world, which is a naughty and lazy habit we've all picked up from Rails.
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
    @id = Order.next_id
    "/orders/#@id"
  end

  private

  def from_json
    order = Order.new(params).save(@id)
    response.body = order.to_json
  end

  def params
    JSON.parse(request.body.to_s)
  end
end
```

# POST to perform a task
* Override `allowed_methods` and `process_post`.  Put all the code to be executed in `process_post`.
* `process_post` must return true, or the HTTP response code
* Response headers like Content-Type will need to be set manually.

```ruby
class DispatchOrderResource < Webmachine::Resource

  def allowed_methods
    ["POST"]
  end

  def resource_exists?
    @order = Order.find(id)
  end

  def process_post
    @order.dispatch
    response.headers['Content-Type'] = 'text/plain'
    response.body = "Successfully dispatched order #{id}"
    true
  end

  private

  def id
    request.path_info[:id]
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

  def resource_exists?
    @order = Order.find(id)
  end

  def from_json
    # Remember PUT should replace the entire resource, not merge the attributes! That's what PATCH is for.
    # It's also why you should not expose your database IDs as your API IDs.
    @order.destroy if @order
    new_order = Order.new(params)
    new_order.save(id)
    response.body = new_order.to_json
  end

  private

  def params
    JSON.parse(request.body.to_s)
  end

  def id
    request.path_info[:id]
  end
end
```

# PATCH
* Webmachine does not currently support PATCH requests. See https://github.com/seancribbs/webmachine-ruby/issues/109 for more information and https://github.com/bethesque/pact_broker/blob/2918814e70bbda14df68598a6a41502a5eac4308/lib/pact_broker/api/resources/pacticipant.rb for a dirty hack to make it work if you need to.

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
    @order = Order.find(id)
  end

  def delete_resource
    Order.find(id).destroy
    true
  end

  private

  def id
    request.path_info[:id]
  end

end
```
