require 'logger'

RSpec.configure do |config|
  config.before(:suite) do
    options = {
      :Logger => Logger.new("/dev/null"),
      :AccessLog => []
    }
    Webmachine::Adapters::WEBrick::DEFAULT_OPTIONS.merge! options
    Webmachine::Adapters::Rack::DEFAULT_OPTIONS.merge! options
  end
end
