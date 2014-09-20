# Authentication

To secure a resource, override the `is_authorized?` method to return a boolean indicating whether or not the client is authenticated (ie. your application believes they are who they say they are). Confusingly, the HTTP "401 Unauthorized" response code actually relates to authentication, not authorization (see the [Authorization](#authorization) section below).

## HTTP Basic Auth

```ruby

class MySecureResource < Webmachine::Resource

  include Webmachine::Resource::Authentication

  def is_authorized?(authorization_header)
    basic_auth(authorization_header, "My Application") do |username, password|
      @user = User.find_by_username(username)
      !@user.nil? && @user.auth?(password)
    end
  end

end

```

# Authorization

Once the client is authenticated (that is, you believe they are who they say they are), override `forbidden?` to return true if the client does not have permission to perform the given method this resource.

```ruby

class MySecureResource < Webmachine::Resource

  def forbidden?
    MySecureResourcePolicy.new(@user, my_secure_domain_model).forbidden?(request.method)
  end

end
```
