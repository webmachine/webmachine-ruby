require 'spec_helper'

describe Webmachine::Decision::FSM do
  include_context 'default resource'

  subject { described_class.new(resource, request, response) }

  let(:run_with_exception) do
    begin
      subject.run
    rescue Exception
    end
  end

  describe 'handling of exceptions from decision methods' do
    let(:UNRESCUABLE_exceptions) do
      Webmachine::RescuableException::UNRESCUABLE
    end

    describe "rescueable exceptions" do
      it 'does rescue Exception' do
        allow(subject).to receive(Webmachine::Decision::Flow::START) { raise(Exception) }
        expect(resource).to receive(:handle_exception).with instance_of(Exception)
        expect { subject.run }.to_not raise_error
      end

      it 'does rescue a failed require' do
        allow(subject).to receive(Webmachine::Decision::Flow::START) { require 'laterequire' }
        expect(resource).to receive(:handle_exception).with instance_of(LoadError)
        expect { subject.run }.to_not raise_error
      end
    end

    describe "UNRESCUABLE exceptions"  do
      shared_examples "UNRESCUABLE" do |e|
        specify "#{e} is not rescued" do
          allow(subject).to receive(Webmachine::Decision::Flow::START) {raise(e)}
          expect(resource).to_not receive(:handle_exception).with instance_of(e)
          expect { subject.run }.to raise_error(e)
        end
      end
      eary = Webmachine::RescuableException::UNRESCUABLE_DEFAULTS - [
        Webmachine::MalformedRequest, # Webmachine rescues by default, so it won't re-raise.
        SignalException # Requires raise in form 'raise SignalException, "SIGSOMESIGNAL"'.
                        # Haven't found a good no-op signal to use here.
      ]
      eary.each{|e| include_examples "UNRESCUABLE", e}
    end
  end

  describe 'handling of errors from decision methods' do
    let(:error) { RuntimeError.new }

    before do
      allow(subject).to receive(Webmachine::Decision::Flow::START) { raise error }
    end

    it 'calls resource.handle_exception' do
      expect(resource).to receive(:handle_exception).with(error)
      subject.run
    end

    it 'calls resource.finish_request' do
      expect(resource).to receive(:finish_request)
      subject.run
    end
  end

  describe 'handling of errors from resource.handle_exception' do
    let(:error) { RuntimeError.new('an error message') }

    before do
      allow(subject).to receive(Webmachine::Decision::Flow::START) { raise }
      allow(resource).to receive(:handle_exception) { raise error }
    end

    it 'does not call resource.handle_exception again' do
      expect(resource).to receive(:handle_exception).once { raise }
      subject.run
    end

    it 'does not call resource.finish_request' do
      expect(resource).not_to receive(:finish_request)
      subject.run
    end

    it 'renders an error' do
      expect(Webmachine).
        to receive(:render_error).
        with(500, request, response, { :message => error.message })
      subject.run
    end
  end

  describe 'handling of exceptions from resource.finish_request' do
    let(:exception) { Class.new(Exception).new }

    before do
      Webmachine::RescuableException.remove(exception)
      allow(resource).to receive(:finish_request) { raise exception }
    end

    it 'does not call resource.handle_exception' do
      expect(resource).to_not receive(:handle_exception)
      run_with_exception
    end

    it 'does not call resource.finish_request again' do
      expect(resource).to_not receive(:finish_request).once { raise }
      run_with_exception
    end
  end

  describe 'handling of errors from resource.finish_request' do
    let(:error) { RuntimeError.new }

    before do
      allow(resource).to receive(:finish_request) { raise error }
    end

    it 'calls resource.handle_exception' do
      expect(resource).to receive(:handle_exception).with(error)
      subject.run
    end

    it 'does not call resource.finish_request again' do
      expect(resource).to receive(:finish_request).once { raise }
      subject.run
    end
  end

  it "sets the response code before calling finish_request" do
    resource_class.class_eval do
      class << self
        attr_accessor :current_response_code
      end

      def to_html
        201
      end

      def finish_request
        self.class.current_response_code = response.code
      end
    end

    subject.run

    expect(resource_class.current_response_code).to be(201)
  end

  it 'respects a response code set by resource.finish_request' do
    resource_class.class_eval do
      def finish_request
        response.code = 451
      end
    end

    subject.run

    expect(response.code).to be(451)
  end
end
