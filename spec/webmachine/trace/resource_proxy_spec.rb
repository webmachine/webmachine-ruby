require 'spec_helper'
require 'webmachine/trace/resource_proxy'

describe Webmachine::Trace::ResourceProxy do
  include_context "default resource"
  subject { described_class.new(resource) }

  it "duck-types all callback methods" do
    Webmachine::Resource::Callbacks.instance_methods(false).each do |m|
      expect(subject).to respond_to(m)
    end
  end

  it "logs invocations of callbacks" do
    subject.generate_etag
    expect(response.trace).to eq([{:type => :attempt, :name => "(default)#generate_etag"},
                              {:type => :result, :value => nil}])

  end

  it "logs invocations of body-producing methods" do
    expect(subject.content_types_provided).to eq([["text/html", :to_html]])
    subject.to_html
    expect(response.trace[-2][:type]).to eq(:attempt)
    expect(response.trace[-2][:name]).to match(/to_html$/)
    expect(response.trace[-2][:source]).to include("spec_helper.rb") if response.trace[-2][:source]
    expect(response.trace[-1]).to eq({:type => :result, :value => "<html><body>Hello, world!</body></html>"})
  end

  it "sets the trace id header when the request has finished processing" do
    subject.finish_request
    expect(response.headers["X-Webmachine-Trace-Id"]).to eq(subject.object_id.to_s)
  end
end
