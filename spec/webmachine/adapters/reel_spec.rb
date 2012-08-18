require 'spec_helper'

describe Webmachine::Adapters::Reel do
	let(:configuration) { Webmachine::Configuration.default }
	let(:dispatcher) { Webmachine::Dispatcher.new }
	let(:adapter) do
		described_class.new(configuration, dispatcher)
	end

	it 'inherits from Webmachine::Adapter' do
		adapter.should be_a_kind_of(Webmachine::Adapter)
	end

	it 'implements #run' do
		adapter.should respond_to(:run)
	end

	it 'implements #process' do
		adapter.should respond_to(:process)
	end
end
