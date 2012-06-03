
module Webmachine
  class Resource
    # Helper module to provide a #url_for method.
    # Requires a @url_provider instance variable.
    module UrlHelpers
      # Get the URL to the given resource, with optional variables to be used
      # for bindings in the path spec.
      # @param [Webmachine::Resource] resource the resource to link to
      # @param [Hash] vars the values for the required path variables
      # @return [String] the URL
      def url_for(resource, vars = {})
        @url_provider.url_for(resource, vars)
      end
    end
  end
end
