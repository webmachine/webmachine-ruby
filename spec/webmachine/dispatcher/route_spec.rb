require 'spec_helper'

describe Webmachine::Dispatcher::Route do
  let(:method) { "GET" }
  let(:uri) { URI.parse("http://localhost:8080/") }
  let(:request){ Webmachine::Request.new(method, uri, Webmachine::Headers.new, "") }
  let(:resource){ Class.new(Webmachine::Resource) }

  matcher :match_route do |*expected|
    route = described_class.new(expected[0], resource, expected[1] || {})
    match do |actual|
      request.uri.path = actual if String === actual
      route.match?(request)
    end

    failure_message_for_should do |_|
      "expected route #{expected[0].inspect} to match path #{request.uri.path}"
    end
    failure_message_for_should_not do |_|
      "expected route #{expected[0].inspect} not to match path #{request.uri.path}"
    end
  end

  context "matching a request" do
    context "on the root path" do
      subject { "/" }
      it { should match_route([]) }
      it { should match_route ['*'] }
      it { should_not match_route %w{foo} }
      it { should_not match_route [:id] }
    end

    context "on a deep path" do
      subject { "/foo/bar/baz" }
      it { should match_route %w{foo bar baz} }
      it { should match_route ['foo', :id, "baz"] }
      it { should match_route %w{foo *} }
      it { should match_route [:id, '*'] }
      it { should_not match_route [] }
      it { should_not match_route %w{bar *} }
    end

    context "with a guard on the request method" do
      let(:uri){ URI.parse("http://localhost:8080/notes") }
      let(:route) do
        described_class.new(
                            ["notes"],
                            lambda { |request| request.method == "POST" },
                            resource
                            )
      end
      subject { route }

      context "when guard passes" do
        let(:method){ "POST" }
        it { should be_match(request) }

        context "but the path match fails" do
          let(:uri){ URI.parse("http://localhost:8080/other") }
          it { should_not be_match(request) }
        end
      end

      context "when guard fails" do
        let(:method) { "GET" }
        it { should_not be_match(request) }
      end
    end
  end

  context "applying bindings" do
    context "on the root path" do
      subject { described_class.new([], resource) }
      before { subject.apply(request) }

      it "should assign the dispatched path to the empty string" do
        request.disp_path.should == ""
      end

      it "should assign empty bindings" do
        request.path_info.should == {}
      end

      it "should assign empty path tokens" do
        request.path_tokens.should == []
      end

      context "with extra user-defined bindings" do
        subject { described_class.new([], resource, "bar" => "baz") }

        it "should assign the user-defined bindings" do
          request.path_info.should == {"bar" => "baz"}
        end
      end

      context "with a splat" do
        subject { described_class.new(['*'], resource) }

        it "should assign empty path tokens" do
          request.path_tokens.should == []
        end
      end
    end

    context "on a deep path" do
      subject { described_class.new(%w{foo bar baz}, resource) }
      before { request.uri.path = "/foo/bar/baz"; subject.apply(request) }

      it "should assign the dispatched path as the path past the initial slash" do
        request.disp_path.should == "foo/bar/baz"
      end

      it "should assign empty bindings" do
        request.path_info.should == {}
      end

      it "should assign empty path tokens" do
        request.path_tokens.should == []
      end

      context "with path variables" do
        subject { described_class.new(['foo', :id, 'baz'], resource) }

        it "should assign the path variables in the bindings" do
          request.path_info.should == {:id => "bar"}
        end
      end

      context "with a splat" do
        subject { described_class.new(%w{foo *}, resource) }

        it "should capture the path tokens matched by the splat" do
          request.path_tokens.should == %w{ bar baz }
        end
      end
    end
  end
end
