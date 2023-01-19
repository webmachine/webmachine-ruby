require 'spec_helper'
require 'webmachine/chunked_body'

describe Webmachine::ChunkedBody do
  it 'builds a proper body' do
    body = ''
    Webmachine::ChunkedBody.new(['foo', 'bar', '', 'j', 'webmachine']).each do |chunk|
      body << chunk
    end
    expect(body).to eq("3\r\nfoo\r\n3\r\nbar\r\n1\r\nj\r\na\r\nwebmachine\r\n0\r\n\r\n")
  end

  context 'with an empty body' do
    it 'builds a proper body' do
      body = ''
      Webmachine::ChunkedBody.new([]).each do |chunk|
        body << chunk
      end
      expect(body).to eq("0\r\n\r\n")
    end
  end

  describe '#each' do
    context 'without a block given' do
      it 'returns an Enumerator' do
        expect(Webmachine::ChunkedBody.new([]).each).to respond_to(:next)
      end
    end
  end
end
