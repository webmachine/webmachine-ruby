require 'spec_helper'

describe Webmachine::QuotedString do
  include Webmachine::QuotedString

  describe '#quote' do
    context 'when the string is present and nonempty, has no quotes' do
      subject { quote('123') }

      it { is_expected.to eq('"123"') }
    end

    context 'when the string is present and nonempty, has embedded quotes' do
      let(:string) { '1"2"3' }
      subject { quote('1"2"3') }

      it { is_expected.to eq('"1\"2\"3"') }
    end

    context 'when the string is present and empty' do
      subject { quote('') }

      it { is_expected.to eq("\"\"") }
    end

    context 'when the string is nil' do
      subject { quote(nil) }

      it { is_expected.to eq("\"\"") }
    end
  end

  describe '#unquote' do
    context 'when the string is present and nonempty, has no quotes' do
      subject { unquote('123') }

      it { is_expected.to eq('123') }
    end

    context 'when the string is present and nonempty, has embedded quotes' do
      let(:string) { '"1\"2\"3"' }
      subject { unquote(string) }

      it { is_expected.to eq('1"2"3') }
    end

    context 'when the string is present and empty' do
      subject { unquote('') }

      it { is_expected.to eq('') }
    end

    context 'when the string is nil' do
      subject { unquote(nil) }

      it { is_expected.to eq(nil) }
    end
  end
end
