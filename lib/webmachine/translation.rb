require 'i18n'
I18n.enforce_available_locales = true if I18n.respond_to?(:enforce_available_locales)
I18n.config.load_path << File.expand_path("../locale/en.yml", __FILE__)

module Webmachine
  # Provides an interface to the I18n library specifically for
  # {Webmachine}'s messages.
  module Translation
    # Interpolates an internationalized string.
    # @param [String] key the name of the string to interpolate
    # @param [Hash] options options to pass to I18n, including
    #   variables to interpolate.
    # @return [String] the interpolated string
    def t(key, options={})
      ::I18n.t(key, options.merge(:scope => :webmachine))
    end
  end
end
