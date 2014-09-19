# Versioning APIs

## By URL

```ruby

class MyResourceV1 < Webmachine::Resource

end

class MyResourceV2 < Webmachine::Resource

end

App = Webmachine::Application.new do |app|
  app.routes do
    add ["api", "v1", "myresource"], MyResourceV1
    add ["api", "v2", "myresource"], MyResourceV2
  end
end

```

## By Content-Type

Note: if no Accept header is specified, then the first content type in the list will be chosen.

```ruby

class MyResource < Webmachine::Resource

  def content_types_provided
    [
      ["application/myapp.v2+json", :to_json_v2],
      ["application/myapp.v1+json", :to_json_v1]
    ]
  end

end

```
