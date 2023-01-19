require 'spec_helper'

describe Webmachine::MediaType do
  let(:raw_type) { 'application/xml;charset=UTF-8' }
  subject { described_class.new('application/xml', {'charset' => 'UTF-8'}) }

  context 'equivalence' do
    it { is_expected.to eq(raw_type) }
    it { is_expected.to eq(described_class.parse(raw_type)) }
  end

  context 'when it is the wildcard type' do
    subject { described_class.new('*/*') }
    it { is_expected.to be_matches_all }
  end

  context 'parsing a type' do
    it 'should return MediaTypes untouched' do
      expect(described_class.parse(subject)).to equal(subject)
    end

    it 'should parse a String' do
      type = described_class.parse(raw_type)
      expect(type).to be_kind_of(described_class)
      expect(type.type).to eq('application/xml')
      expect(type.params).to eq({'charset' => 'UTF-8'})
    end

    it 'should parse a type/params pair' do
      type = described_class.parse(['application/xml', {'charset' => 'UTF-8'}])
      expect(type).to be_kind_of(described_class)
      expect(type.type).to eq('application/xml')
      expect(type.params).to eq({'charset' => 'UTF-8'})
    end

    it 'should parse a type/params pair where the type has some params in the string' do
      type = described_class.parse(['application/xml;version=1', {'charset' => 'UTF-8'}])
      expect(type).to be_kind_of(described_class)
      expect(type.type).to eq('application/xml')
      expect(type.params).to eq({'charset' => 'UTF-8', 'version' => '1'})
    end

    it 'should parse a type/params pair with params and whitespace in the string' do
      type = described_class.parse(['multipart/form-data; boundary=----------------------------2c46a7bec2b9', {'charset' => 'UTF-8'}])
      expect(type).to be_kind_of(described_class)
      expect(type.type).to eq('multipart/form-data')
      expect(type.params).to eq({'boundary' => '----------------------------2c46a7bec2b9', 'charset' => 'UTF-8'})
    end

    it 'should parse a type/params pair where type has single-token params' do
      type = described_class.parse(['text/html;q=1;rdfa', {'charset' => 'UTF-8'}])
      expect(type).to be_kind_of(described_class)
      expect(type.type).to eq('text/html')
      expect(type.params).to eq({'q' => '1', 'rdfa' => '', 'charset' => 'UTF-8'})
    end

    it 'should raise an error when given an invalid type/params pair' do
      expect {
        described_class.parse([false, 'blah'])
      }.to raise_error(ArgumentError)
    end
  end

  describe 'matching a requested type' do
    it { is_expected.to be_exact_match('application/xml;charset=UTF-8') }
    it { is_expected.to be_exact_match('application/*;charset=UTF-8') }
    it { is_expected.to be_exact_match('*/*;charset=UTF-8') }
    it { is_expected.to be_exact_match('*;charset=UTF-8') }
    it { is_expected.not_to be_exact_match('text/xml') }
    it { is_expected.not_to be_exact_match('application/xml') }
    it { is_expected.not_to be_exact_match('application/xml;version=1') }

    it { is_expected.to be_type_matches('application/xml') }
    it { is_expected.to be_type_matches('application/*') }
    it { is_expected.to be_type_matches('*/*') }
    it { is_expected.to be_type_matches('*') }
    it { is_expected.not_to be_type_matches('text/xml') }
    it { is_expected.not_to be_type_matches('text/*') }

    it { is_expected.to be_params_match({}) }
    it { is_expected.to be_params_match({'charset' => 'UTF-8'}) }
    it { is_expected.not_to be_params_match({'charset' => 'Windows-1252'}) }
    it { is_expected.not_to be_params_match({'version' => '3'}) }
  end
end
