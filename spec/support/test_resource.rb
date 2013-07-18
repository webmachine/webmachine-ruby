module Test
  class Resource < Webmachine::Resource
    def allowed_methods
      ["GET", "PUT", "POST"]
    end

    def content_types_accepted
      [
        ["test/request.stringbody", :from_string],
        ["test/request.enumbody", :from_enum]
      ]
    end

    def content_types_provided
      [
        ["test/response.stringbody", :to_string],
        ["test/response.enumbody", :to_enum],
        ["test/response.procbody", :to_proc],
        ["test/response.fiberbody", :to_fiber],
        ["test/response.iobody", :to_io],
        ["test/response.cookies", :to_cookies]
      ]
    end

    def from_string
      response.body = "String: #{request.body.to_s}"
    end

    def from_enum
      response.body = "Enum: "
      request.body.each do |part|
        response.body += part
      end
    end

    # Response intentionally left blank to test 204 support
    def process_post
      true
    end

    def to_string
      "String response body"
    end

    def to_enum
      ["Enumerable ", "response " "body"]
    end

    def to_proc
      Proc.new { "Proc response body" }
    end

    def to_fiber
      Fiber.new do
        Fiber.yield "Fiber "
        Fiber.yield "response "
        Fiber.yield "body"
      end
    end

    def to_io
      StringIO.new("IO response body")
    end

    def to_cookies
      response.set_cookie("cookie", "monster")
      response.set_cookie("rodeo", "clown")
      # FIXME: Mongrel/WEBrick fail if this method returns nil
      # Might be a net/http issue. Is this a bug?
      request.cookies["echo"] || ""
    end
  end
end
