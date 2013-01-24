module Test
  class Resource < Webmachine::Resource
    def allowed_methods
      ["GET", "PUT", "POST"]
    end

    def content_types_accepted
      [["application/json", :from_json]]
    end

    def content_types_provided
      [
        ["text/html", :to_html],
        ["application/vnd.webmachine.streaming+enum", :to_enum_stream],
        ["application/vnd.webmachine.streaming+proc", :to_proc_stream]
      ]
    end

    def process_post
      true
    end

    def to_html
      response.set_cookie('cookie', 'monster')
      response.set_cookie('rodeo', 'clown')
      "<html><body>#{request.cookies['string'] || 'testing'}</body></html>"
    end

    def to_enum_stream
      %w{Hello, World!}
    end

    def to_proc_stream
      Proc.new { "Stream" }
    end

    def from_json; end
  end
end
