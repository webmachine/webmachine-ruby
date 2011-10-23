require 'spec_helper'

describe Webmachine::Dispatcher do
  let(:dispatcher) { described_class }
  let(:request) { Webmachine::Request.new("GET", URI.parse("http://localhost:8080/"), Webmachine::Headers["accept" => "*/*"], "") }
  let(:response) { Webmachine::Response.new }
  let(:resource) do
    Class.new(Webmachine::Resource) do
      def to_html; "hello world!"; end
    end
  end
  let(:resource2) do
    Class.new(Webmachine::Resource) do
      def to_html; "goodbye, cruel world"; end
    end
  end
  let(:fsm){ mock }
  
  before { dispatcher.reset }

  it "should add routes from a block" do
    _resource = resource
    Webmachine.routes do
      add ['*'], _resource
    end.should == Webmachine
    dispatcher.instance_variable_get(:@routes).should have(1).item
  end
  
  it "should add routes" do
    expect {
      dispatcher.add_route ['*'], resource
    }.should_not raise_error
  end

  it "should have add_route return the newly created route" do
    route = dispatcher.add_route ['*'], resource
    route.should be_instance_of Webmachine::Dispatcher::Route
  end

  it "should route to the proper resource" do
    dispatcher.add_route ["goodbye"], resource2
    dispatcher.add_route ['*'], resource    
    Webmachine::Decision::FSM.should_receive(:new).with(instance_of(resource), request, response).and_return(fsm)
    fsm.should_receive(:run)
    dispatcher.dispatch(request, response)
  end
end
