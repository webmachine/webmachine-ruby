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

## By Header value

```ruby

class MyResourceV1 < Webmachine::Resource

end

class MyResourceV2 < Webmachine::Resource

end

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
    add ["api", "myresource"], VersionGuard.new("1"), MyResourceV1
    add ["api", "myresource"], VersionGuard.new("2"), MyResourceV2
  end
end

```
