require 'spec_helper'

describe Webmachine::Dispatcher do
  let(:dispatcher) { Webmachine.application.dispatcher }
  let(:request) { Webmachine::Request.new("GET", URI.parse("http://localhost:8080/"), Webmachine::Headers["accept" => "*/*"], "") }
  let(:request2) { Webmachine::Request.new("GET", URI.parse("http://localhost:8080/hello/bob.html"), Webmachine::Headers["accept" => "*/*"], "") }
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
  let(:resource3) do
    Class.new(Webmachine::Resource) do
      def to_html
        name, format = request.path_info[:captures]
        "Hello #{name} with #{format}"
      end
    end
  end
  let(:fsm){ double }

  before { dispatcher.reset }

  it "should add routes from a block" do
    _resource = resource
    expect(Webmachine.routes do
      add [:*], _resource
    end).to eq(Webmachine)
    expect(dispatcher.routes.size).to eq(1)
  end

  it "should add routes" do
    expect {
      dispatcher.add_route [:*], resource
    }.to_not raise_error
  end

  it "should have add_route return the newly created route" do
    route = dispatcher.add_route [:*], resource
    expect(route).to be_instance_of Webmachine::Dispatcher::Route
  end

  it "should route to the proper resource" do
    dispatcher.add_route ["goodbye"], resource2
    dispatcher.add_route [:*], resource
    expect(Webmachine::Decision::FSM).to receive(:new).with(instance_of(resource), request, response).and_return(fsm)
    expect(fsm).to receive(:run)
    dispatcher.dispatch(request, response)
  end
  it "should handle regex path segments in route definition" do
    dispatcher.add_route ["hello", /(.*)\.(.*)/], resource3
    expect(Webmachine::Decision::FSM).to receive(:new).with(instance_of(resource3), request2, response).and_return(fsm)
    expect(fsm).to receive(:run)
    dispatcher.dispatch(request2, response)
  end

  it "should apply route to request before creating the resource" do
    route   = dispatcher.add_route [:*], resource
    applied = false

    expect(route).to receive(:apply) { applied = true }
    expect(resource).to(receive(:new) do
      expect(applied).to be(true)
      resource2.new(request, response)
    end)

    dispatcher.dispatch(request, response)
  end

  it "should add routes with guards" do
    dispatcher.add [], lambda {|req| req.method == "POST" }, resource
    dispatcher.add [:*], resource2 do |req|
      !req.query.empty?
    end
    request.uri.query = "?foo=bar"
    expect(dispatcher.routes.size).to eq(2)
    expect(Webmachine::Decision::FSM).to receive(:new).with(instance_of(resource2), request, response).and_return(fsm)
    expect(fsm).to receive(:run)
    dispatcher.dispatch(request, response)
  end

  it "should respond with a valid resource for a 404" do
    dispatcher.dispatch(request, response)
    expect(response.code).to     eq(404)
    expect(response.body).to_not be_empty
    expect(response.headers).to  have_key('Content-Length')
    expect(response.headers).to  have_key('Date')
  end

  it "should respond with a valid resource for a 404 with a custom Accept header" do
    request.headers['Accept'] = "application/json"
    dispatcher.dispatch(request, response)
    expect(response.code).to     eq(404)
    expect(response.body).to_not be_empty
    expect(response.headers).to  have_key('Content-Length')
    expect(response.headers).to  have_key('Date')
  end
end
