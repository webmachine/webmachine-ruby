
module Webmachine
  class Resource
    module UrlHelpers
      def url_for(resource, vars = {})
        @url_provider.url_for(resource, vars)
      end
    end
  end
end
