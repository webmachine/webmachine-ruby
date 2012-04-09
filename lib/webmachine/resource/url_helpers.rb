
module Webmachine
  class Resource
    module UrlHelpers
      def url_for(resource, vars = {})
        @dispatcher.url_for(resource, vars)
      end
    end
  end
end
