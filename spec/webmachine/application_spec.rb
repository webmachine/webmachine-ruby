require 'spec_helper'

describe Webmachine::Application do
  let(:application) { described_class.new }
  let(:test_resource) { Class.new(Webmachine::Resource) }

  it "accepts a Configuration when initialized" do
    config = Webmachine::Configuration.new('1.1.1.1', 9999, :Mongrel, {})
    expect(described_class.new(config).configuration).to be(config)
  end

  it "is yielded into a block provided during initialization" do
    yielded_app = nil
    returned_app = described_class.new do |app|
      expect(app).to be_kind_of(Webmachine::Application)
      yielded_app = app
    end
    expect(returned_app).to be(yielded_app)
  end

  it "is initialized with the default Configration if none is given" do
    expect(application.configuration).to eq(Webmachine::Configuration.default)
  end

  it "returns the receiver from the configure call so you can chain it" do
    expect(application.configure { |c| }).to equal(application)
  end

  it "is configurable" do
    application.configure do |config|
      expect(config).to be_kind_of(Webmachine::Configuration)
    end
  end

  it "is initialized with an empty Dispatcher" do
    expect(application.dispatcher.routes).to be_empty
  end

  it "can have routes added" do
    route = nil
    resource = test_resource # overcome instance_eval :/

    expect(application.routes).to be_empty

    application.routes do
      route = add ['*'], resource
    end

    expect(route).to be_kind_of(Webmachine::Dispatcher::Route)
    expect(application.routes).to eq([route])
  end

  describe "#adapter" do
    let(:adapter_class) { application.adapter_class }

    it "returns an instance of it's adapter class" do
      expect(application.adapter).to be_an_instance_of(adapter_class)
    end

    it "is memoized" do
      expect(application.adapter).to eql application.adapter
    end
  end

  it "can be run" do
    expect(application.adapter).to receive(:run)
    application.run
  end

  it "can be queried about its configured adapter" do
    expected = Webmachine::Adapters.const_get(application.configuration.adapter)
    expect(application.adapter_class).to equal(expected)
  end
end
