# Error handling

## Handling runtime errors

Runtime errors should happen infrequently when using Webmachine, as many of the potential causes of "error" will have already been checked in the appropriate callback, and handled with a meaningful HTTP response code (eg. `resource_exists?` or `is_authorized?`).

To return a custom error response, override `handle_exception` and modify the response body and headers as desired.

```ruby

class MyResource < Webmachine::Resource

  def handle_exception e
    response.headers['Content-Type'] = 'application/json'
    response.body = {:message => e.message, :backtrace => e.backtrace }.to_json
  end

end

```

Given that this should be a genuine "Server Error", the response code is set to 500, and cannot be overridden in `handle_exception`. If you must set a custom error response code, but were unable to use one of the previous callbacks to set it, use `finish_request` to set the response code as desired.

## Customising the error response

You can modify the response headers and body in any callback.

```ruby

class MyResource < Webmachine::Resource

  def resource_exists?
    @droid = Droid.find(request.path_info[:droid_id]).tap do | droid |
      unless droid
        response.headers['Content-Type'] = "text/plain"
        response.body = "These aren't the droids you're looking for."
      end
    end
  end

end

```

## Returning a custom error code

If your response code cannot be determined in an appropriate callback, returning an integer response code from most of the callbacks will cause the response to be returned immediately. You generally only want to do this when new information comes to light, requiring a modification of the response.

```ruby

class MyResource < Webmachine::Resource

  def content_types_accepted
    [
      ["application/json", :from_json],
      ["application/xml", :from_xml]
    ]
  end

  def malformed_request?
    # Is this JSON or XML? Don't know without a messy if statement.
    # Maybe cleaner to decide in the response handler for the appropriate Content-Type?
    false
  end

  def from_json
    return 400 if invalid_json?
    ...
  end

  def from_xml
    return 400 if invalid_xml?
    ...
  end

  def invalid_json?
    ...
  end

  def invalid_xml?
    ...
  end

end

```
