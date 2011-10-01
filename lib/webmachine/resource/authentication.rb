module Webmachine
  class Resource
    # Helper methods that can be included in your
    # {Webmachine::Resource} to assist in performing HTTP
    # Authentication.
    module Authentication
      BASIC_HEADER = /^Basic (.*)$/i.freeze

      # A simple implementation of HTTP Basic auth. Call this from the
      # {Webmachine::Resource::Callbacks#is_authorized?} callback,
      # giving it a block which will be yielded the username and
      # password and return true or false.      
      # @param [String] header the value of the Authentication request
      #   header, passed to the {Callbacks#is_authorized?} callback.
      # @param [String] realm the "realm", or description of the
      #   resource that requires authentication
      # @return [true, String] true if the client is authorized, or
      #   the appropriate WWW-Authenticate header
      # @yield [user, password] a block that will verify the client-provided user/password
      #   against application constraints
      # @yieldparam [String] user the passed username
      # @yieldparam [String] password the passed password
      # @yieldreturn [true,false] whether the username/password is correct
      def basic_auth(header, realm="Webmachine")
        if header =~ BASIC_HEADER && (yield *$1.unpack('m*').first.split(/:/,2))
          true
        else
          %Q[Basic realm="#{realm}"]
        end
      end
    end
  end
end
