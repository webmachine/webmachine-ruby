$LOAD_PATH << File.expand_path("..", __FILE__)
$LOAD_PATH << File.expand_path("../../lib", __FILE__)

require 'rubygems'
require 'webmachine'
require 'rspec'

RSpec.configure do |config|
  config.mock_with :rspec
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
  config.treat_symbols_as_metadata_keys_with_true_values = true
end
