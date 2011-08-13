require 'webmachine/translation'
require 'webmachine/version'

module Webmachine
  extend Translation

  # Renders a standard error message body for the response. The
  # standard messages are defined in localization files.
  # @param [Fixnum] code the response status code
  # @param [Request] req the request object
  # @param [Response] req the response object
  def self.render_error(code, req, res)
    unless res.body
      title, message = t(["errors.#{code}.title", "errors.#{code}.message"],
                         :method => req.method,
                         :error => res.error)
      res.body = t("errors.standard_body",
                   :title => title,
                   :message => message,
                   :version => Webmachine::SERVER_STRING)
      res['Content-Type'] = "text/html"
    end
  end
end
