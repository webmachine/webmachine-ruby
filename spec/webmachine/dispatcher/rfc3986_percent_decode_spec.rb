require 'spec_helper'

describe Webmachine::Dispatcher::Route do
  describe '#rfc3986_percent_decode' do
    def call_subject(value)
      Webmachine::Dispatcher::Route.rfc3986_percent_decode(value)
    end

    it 'does not change un-encoded strings' do
      expect(call_subject('this is a normal string, I think')).to eq 'this is a normal string, I think'
      expect(call_subject('')).to eq ''
    end

    it 'decodes percent encoded sequences' do
      expect(call_subject('/tenants/esckimo+test%20%65')).to eq '/tenants/esckimo+test e'
    end

    it 'leaves incorrectly encoded sequences as is' do
      expect(call_subject('/tenants/esckimo+test%2%65')).to eq '/tenants/esckimo+test%2e'
    end
  end
end
