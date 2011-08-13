require 'i18n'

I18n.config.load_path << File.expand_path("../locale/en.yml", __FILE__)

module Webmachine
  module Translation
    def t(key, options={})
      ::I18n.t(key, options.merge(:scope => :webmachine))
    end
  end
end
