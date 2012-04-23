require 'spec_helper'
require 'webmachine/trace/resource_proxy'

describe Webmachine::Trace::ResourceProxy do
  let(:method) { 'GET' }
  let(:uri) { URI.parse("http://localhost/") }
  let(:headers) { Webmachine::Headers.new }
  let(:body) { "" }
  let(:request) { Webmachine::Request.new(method, uri, headers, body) }
  let(:response) { Webmachine::Response.new }

  let(:resource_class) do
    Class.new(Webmachine::Resource) do
      def to_html
        "<html><body>Hello, world!</body></html>"
      end
    end
  end
  let(:resource) { resource_class.new(request, response) }
  subject { described_class.new(resource) }

  it "duck-types all callback methods" do
    Webmachine::Resource::Callbacks.instance_methods(false).each do |m|
      subject.should respond_to(m)
    end
  end

  it "logs invocations of callbacks" do
    subject.generate_etag
    response.trace.should == [{:type => :attempt, :name => "(default)#generate_etag"},
                              {:type => :result, :value => nil}]

  end

  it "logs invocations of body-producing methods" do
    subject.content_types_provided.should == [["text/html", :to_html]]
    subject.to_html
    response.trace[-2][:type].should == :attempt
    response.trace[-2][:name].should =~ /to_html$/
    response.trace[-2][:source].should include(__FILE__)
    response.trace[-1].should == {:type => :result, :value => "<html><body>Hello, world!</body></html>"}
  end

  it "commits the trace to separate storage when the request has finished processing" do
    Webmachine::Trace.should_receive(:record).with(subject.object_id.to_s, [{:type=>:attempt, :name=>"(default)#finish_request"},
                                                                       {:type=>:result, :value=>nil}]).and_return(true)
    subject.finish_request
    response.headers["X-Webmachine-Trace-Id"].should == subject.object_id.to_s
  end
end
