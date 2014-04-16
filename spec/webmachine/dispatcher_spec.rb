require 'spec_helper'

describe Webmachine::Dispatcher do
  let(:dispatcher) { Webmachine.application.dispatcher }
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
    dispatcher.routes.should have(1).item
  end

  it "should add routes" do
    expect {
      dispatcher.add_route ['*'], resource
    }.to_not raise_error
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

  it "should apply route to request before creating the resource" do
    route   = dispatcher.add_route ["*"], resource
    applied = false

    route.should_receive(:apply) { applied = true }
    resource.should_receive(:new) do
      applied.should be_true
      resource2.new(request, response)
    end

    dispatcher.dispatch(request, response)
  end

  it "should add routes with guards" do
    dispatcher.add [], lambda {|req| req.method == "POST" }, resource
    dispatcher.add ['*'], resource2 do |req|
      !req.query.empty?
    end
    request.uri.query = "?foo=bar"
    dispatcher.routes.should have(2).items
    Webmachine::Decision::FSM.should_receive(:new).with(instance_of(resource2), request, response).and_return(fsm)
    fsm.should_receive(:run)
    dispatcher.dispatch(request, response)
  end

  it "should respond with a valid resource for a 404" do
    dispatcher.dispatch(request, response)
    response.code.should     eq(404)
    response.body.should_not be_empty
    response.headers.should  have_key('Content-Length')
    response.headers.should  have_key('Date')
  end

  it "should respond with a valid resource for a 404 with a custom Accept header" do
    request.headers['Accept'] = "application/json"
    dispatcher.dispatch(request, response)
    response.code.should     eq(404)
    response.body.should_not be_empty
    response.headers.should  have_key('Content-Length')
    response.headers.should  have_key('Date')
  end
end
