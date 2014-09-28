require 'webmachine'

class RouteDebugResource < Webmachine::Resource
  def to_html
    <<-HTML
      <html>
        <head><title>Test from Webmachine</title></head>
        <body>
          <h5>request.disp_path</h5>
          <pre>#{request.disp_path}</pre>
          <h5>request.path_info</h5>
          <pre>#{request.path_info}</pre>
          <h5>request.path_tokens</h5>
          <pre>#{request.path_tokens}</pre>
        </body>
      </html>
    HTML
  end
end

MyApp = Webmachine::Application.new do |app|
  # Configure your app like this:
  app.configure do |config|
    config.port = 8888
    config.adapter = :WEBrick
  end
  # And add routes like this:
  app.add_route ['fizz', :buzz, :*], RouteDebugResource
  # OR add routes this way:
  app.routes do
    add [:test, :foo, :*], RouteDebugResource
  end
end

MyApp.run
