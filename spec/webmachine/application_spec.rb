require 'spec_helper'

describe Webmachine::Application do
  let(:application) { described_class.new }
  let(:test_resource) { Class.new(Webmachine::Resource) }

  it "accepts a Configuration when initialized" do
    config = Webmachine::Configuration.new('1.1.1.1', 9999, :Mongrel, {})
    described_class.new(config).configuration.should be(config)
  end

  it "is yielded into a block provided during initialization" do
    yielded_app = nil
    described_class.new do |app|
      app.should be_kind_of(Webmachine::Application)
      yielded_app = app
    end.should be(yielded_app)
  end

  it "is initialized with the default Configration if none is given" do
    default_conf = Webmachine::Configuration.default
    application.configuration.port = default_conf.port
    application.configuration.should eq(default_conf)
  end

  it "returns the receiver from the configure call so you can chain it" do
    application.configure { |c| }.should equal(application)
  end

  it "is configurable" do
    application.configure do |config|
      config.should be_kind_of(Webmachine::Configuration)
    end
  end

  it "is initialized with an empty Dispatcher" do
    application.dispatcher.routes.should be_empty
  end

  it "can have routes added" do
    route = nil
    resource = test_resource # overcome instance_eval :/

    application.routes.should be_empty

    application.routes do
      route = add ['*'], resource
    end

    route.should be_kind_of(Webmachine::Dispatcher::Route)
    application.routes.should eq([route])
  end

  describe "#adapter" do
    let(:adapter_class) { application.adapter_class }

    it "returns an instance of it's adapter class" do
      application.adapter.should be_an_instance_of(adapter_class)
    end

    it "is memoized" do
      application.adapter.should eql application.adapter
    end
  end

  it "can be run" do
    application.adapter.should_receive(:run)
    application.run
  end

  it "can be queried about its configured adapter" do
    expected = Webmachine::Adapters.const_get(application.configuration.adapter)
    application.adapter_class.should equal(expected)
  end
end
