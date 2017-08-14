require 'spec_helper'

Webmachine::Dispatcher::Route.class_eval do
  def warn(*msgs); end # silence warnings for tests
end

describe Webmachine::Dispatcher::Route do
  let(:method) { "GET" }
  let(:uri) { URI.parse("http://localhost:8080/") }
  let(:routing_tokens) { nil }
  let(:request){ Webmachine::Request.new(method, uri, Webmachine::Headers.new, "", routing_tokens) }
  let(:resource){ Class.new(Webmachine::Resource) }

  describe '#apply' do
    let(:route) {
      Webmachine::Dispatcher::Route.new ['hello', :string], resource, {}
    }

    describe 'a path_info fragment' do
      let(:uri) { URI.parse("http://localhost:8080/hello/planet%20earth%20++") }

      it 'should decode the value' do
        route.apply(request)
        expect(request.path_info).to eq({:string => 'planet earth ++'})
      end
    end
  end

  matcher :match_route do |*expected|
    route = Webmachine::Dispatcher::Route.new(expected[0], Class.new(Webmachine::Resource), expected[1] || {})
    match do |actual|
      uri = URI.parse("http://localhost:8080")
      uri.path = actual
      req = Webmachine::Request.new("GET", uri, Webmachine::Headers.new, "", routing_tokens)
      route.match?(req)
    end

    failure_message do |_|
      "expected route #{expected[0].inspect} to match path #{request.uri.path}"
    end
    failure_message_when_negated do |_|
      "expected route #{expected[0].inspect} not to match path #{request.uri.path}"
    end
  end

  it "warns about the deprecated string splat when initializing" do
    [["*"],["foo", "*"],["foo", :bar, "*"]].each do |path|
      route = described_class.allocate
      expect(route).to receive(:warn)
      route.send :initialize, path, resource, {}
    end
  end

  context "matching a request" do
    context "on the root path" do
      subject { "/" }
      it { is_expected.to match_route([]) }
      it { is_expected.to match_route ['*'] }
      it { is_expected.to match_route [:*] }
      it { is_expected.not_to match_route %w{foo} }
      it { is_expected.not_to match_route [:id] }
    end

    context "on a deep path" do
      subject { "/foo/bar/baz" }
      it { is_expected.to match_route %w{foo bar baz} }
      it { is_expected.to match_route ['foo', :id, "baz"] }
      it { is_expected.to match_route ['foo', :*] }
      it { is_expected.to match_route [:id, :*] }
      it { is_expected.not_to match_route [] }
      it { is_expected.not_to match_route ['bar', :*] }
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
        it { is_expected.to be_match(request) }

        context "but the path match fails" do
          let(:uri){ URI.parse("http://localhost:8080/other") }
          it { is_expected.not_to be_match(request) }
        end
      end

      context "when guard fails" do
        let(:method) { "GET" }
        it { is_expected.not_to be_match(request) }
      end

      context "when the guard responds to #call" do
        let(:guard_class) do
          Class.new do
            def initialize(method)
              @method = method
            end

            def call(request)
              request.method == @method
            end
          end
        end

        let(:route) do
          described_class.new(["notes"], guard_class.new("POST"), resource)
        end

        context "when the guard passes" do
          let(:method){ "POST" }
          it { is_expected.to be_match(request) }
        end

        context "when the guard fails" do
          # let(:method){ "GET" }
          it { is_expected.not_to be_match(request) }
        end
      end
    end

    context "with a request with explicitly specified routing tokens" do
      subject { "/some/route/foo/bar" }
      let(:routing_tokens) { ["foo", "bar"] }
      it { is_expected.to match_route(["foo", "bar"]) }
      it { is_expected.to match_route(["foo", :id]) }
      it { is_expected.to match_route ['*'] }
      it { is_expected.to match_route [:*] }
      it { is_expected.not_to match_route(["some", "route", "foo", "bar"]) }
      it { is_expected.not_to match_route %w{foo} }
      it { is_expected.not_to match_route [:id] }
    end
  end

  context "applying bindings" do
    context "on the root path" do
      subject { described_class.new([], resource) }
      before { subject.apply(request) }

      it "should assign the dispatched path to the empty string" do
        expect(request.disp_path).to eq("")
      end

      it "should assign empty bindings" do
        expect(request.path_info).to eq({})
      end

      it "should assign empty path tokens" do
        expect(request.path_tokens).to eq([])
      end

      context "with extra user-defined bindings" do
        subject { described_class.new([], resource, "bar" => "baz") }

        it "should assign the user-defined bindings" do
          expect(request.path_info).to eq({"bar" => "baz"})
        end
      end

      context "with a splat" do
        subject { described_class.new([:*], resource) }

        it "should assign empty path tokens" do
          expect(request.path_tokens).to eq([])
        end
      end

      context "with a deprecated splat string" do
        subject { described_class.new(['*'], resource) }

        it "should assign empty path tokens" do
          expect(request.path_tokens).to eq([])
        end
      end
    end
    context "on a deep path" do
      subject { described_class.new(%w{foo bar baz}, resource) }
      let(:uri) { URI.parse("http://localhost:8080/foo/bar/baz") }
      before { subject.apply(request) }

      it "should assign the dispatched path as the path past the initial slash" do
        expect(request.disp_path).to eq("foo/bar/baz")
      end

      it "should assign empty bindings" do
        expect(request.path_info).to eq({})
      end

      it "should assign empty path tokens" do
        expect(request.path_tokens).to eq([])
      end

      context "with path variables" do
        subject { described_class.new(['foo', :id, 'baz'], resource) }

        it "should assign the path variables in the bindings" do
          expect(request.path_info).to eq({:id => "bar"})
        end
      end
      context "with regex" do
        subject { described_class.new([/foo/, /(.*)/, 'baz'], resource) }

        it "should assign the captures path variables" do
          expect(request.path_info).to eq({:captures => ["bar"]})
        end
      end
      context "with multi-capture regex" do
        subject { described_class.new([/foo/, /(.*)/, /baz\.(.*)/], resource) }
        let(:uri) { URI.parse("http://localhost:8080/foo/bar/baz.json") }

        it "should assign the captures path variables" do
          expect(request.path_info).to eq({:captures => ["bar", "json"]})
        end
      end
      context "with named capture regex" do
        subject { described_class.new(['foo', :bar, /(?<baz>[^.]+)\.(?<format>.*)/], resource) }
        let(:uri) { URI.parse("http://localhost:8080/foo/bar/baz.json") }

        it "should assign the captures path variables" do
          expect(request.path_info).to eq({bar: 'bar', baz: 'baz', format: "json"})
        end
      end

      context "with a splat" do
        subject { described_class.new(['foo', :*], resource) }

        it "should capture the path tokens matched by the splat" do
          expect(request.path_tokens).to eq(%w{ bar baz })
        end
      end

      context "with a deprecated splat string" do
        subject { described_class.new(%w{foo *}, resource) }

        it "should capture the path tokens matched by the splat" do
          expect(request.path_tokens).to eq(%w{ bar baz })
        end
      end
    end
  end
end
