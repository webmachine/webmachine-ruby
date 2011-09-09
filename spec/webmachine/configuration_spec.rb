require 'spec_helper'

describe Webmachine::Configuration do
  before { Webmachine.configuration = nil }
  
  %w{ip port adapter adapter_options}.each do |field|
    it { should respond_to(field) }
    it { should respond_to("#{field}=") }
  end

  it "should yield configuration to the block" do
    Webmachine.configure do |config|
      config.should be_kind_of(described_class)
    end
  end

  it "should set the global configuration from the yielded instance" do
    Webmachine.configure do |config|
      @config = config
    end
    @config.should == Webmachine.configuration
  end

  it "should return the module from the configure call so you can chain it" do
    Webmachine.configure {|c|}.should == Webmachine
  end
end
