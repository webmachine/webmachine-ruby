require "spec_helper"
require "webmachine/spec/adapter_lint"

begin
  describe Webmachine::Adapters::HTTPkit do
    it_should_behave_like :adapter_lint
  end
rescue LoadError
  warn "Platform is #{RUBY_PLATFORM}: skipping httpkit adapter spec."
end
