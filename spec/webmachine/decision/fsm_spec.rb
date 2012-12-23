require 'spec_helper'

describe Webmachine::Decision::FSM do
  include_context 'default resource'

  subject { described_class.new(resource, request, response) }

  describe 'handling of exceptions from decision methods' do
    let(:exception) { Exception.new }

    before do
      subject.stub(Webmachine::Decision::Flow::START) { raise exception }
    end

    it 'calls resource.handle_exception' do
      resource.should_receive(:handle_exception).with(exception)
      subject.run
    end

    it 'calls resource.finish_request' do
      resource.should_receive(:finish_request)
      subject.run
    end
  end

  describe 'handling of exceptions from resource.handle_exception' do
    let(:exception) { Exception.new('an error message') }

    before do
      subject.stub(Webmachine::Decision::Flow::START) { raise }
      resource.stub(:handle_exception) { raise exception }
    end

    it 'does not call resource.handle_exception again' do
      resource.should_receive(:handle_exception).once { raise }
      subject.run
    end

    it 'does not call resource.finish_request' do
      resource.should_not_receive(:finish_request)
      subject.run
    end

    it 'renders an error' do
      Webmachine.
        should_receive(:render_error).
        with(500, request, response, { :message => exception.message })
      subject.run
    end
  end

  describe 'handling of exceptions from resource.finish_request' do
    let(:exception) { Exception.new }

    before do
      resource.stub(:finish_request) { raise exception }
    end

    it 'calls resource.handle_exception' do
      resource.should_receive(:handle_exception).with(exception)
      subject.run
    end

    it 'does not call resource.finish_request again' do
      resource.should_receive(:finish_request).once { raise }
      subject.run
    end
  end
end
