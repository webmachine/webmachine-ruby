require 'spec_helper'

describe Webmachine::Cookie do
  describe 'creating a cookie' do
    let(:name) { 'monster' }
    let(:value) { 'mash' }
    let(:attributes) { {} }

    let(:cookie) { Webmachine::Cookie.new(name, value, attributes) }

    subject { cookie }

    its(:name) { should == name }
    its(:value) { should == value }

    its(:to_s) { should == 'monster=mash' }

    describe 'a cookie with whitespace in name and value' do
      let(:name) { 'cookie name' }
      let(:value) { 'cookie value' }

      its(:to_s) { should == 'cookie+name=cookie+value' }
    end

    describe 'a cookie with attributes set' do
      let(:domain) { 'www.server.com' }
      let(:path) { '/' }
      let(:comment) { 'comment with spaces' }
      let(:version) { 1 }
      let(:maxage) { 60 }
      let(:expires) { Time.gm(2010, 3, 14, 3, 14, 0) }
      let(:attributes) {
        {
          comment: comment,
          domain: domain,
          path: path,
          secure: true,
          httponly: true,
          version: version,
          maxage: maxage,
          expires: expires
        }
      }

      its(:secure?) { should be true }
      its(:http_only?) { should be true }
      its(:comment) { should == comment }
      its(:domain) { should == domain }
      its(:path) { should == path }
      its(:version) { should == version }
      its(:maxage) { should == maxage }
      its(:expires) { should == expires }

      it 'should include the attributes in its string version' do
        str = subject.to_s
        expect(str).to include 'Secure'
        expect(str).to include 'HttpOnly'
        expect(str).to include 'Comment=comment+with+spaces'
        expect(str).to include 'Domain=www.server.com'
        expect(str).to include 'Path=/'
        expect(str).to include 'Version=1'
        expect(str).to include 'Max-Age=60'
        expect(str).to include 'Expires=Sun, 14 Mar 2010 03:14:00 GMT'
      end
    end
  end

  describe 'parsing a cookie parameter' do
    let(:str) { 'cookie = monster' }

    subject { Webmachine::Cookie.parse(str) }

    it('should have the cookie') { expect(subject).to eq({'cookie' => 'monster'}) }

    describe 'parsing multiple cookie parameters' do
      let(:str) { 'cookie=monster; monster=mash' }

      it('should have both cookies') { expect(subject).to eq({'cookie' => 'monster', 'monster' => 'mash'}) }
    end

    describe 'parsing an encoded cookie' do
      let(:str) { 'cookie=yum+yum' }

      it('should decode the cookie') { expect(subject).to eq({'cookie' => 'yum yum'}) }
    end

    describe 'parsing nil' do
      let(:str) { nil }

      it('should return empty hash') { expect(subject).to eq({}) }
    end

    describe 'parsing duplicate cookies' do
      let(:str) { 'cookie=monster; cookie=yum+yum' }

      it('should return the first instance of the cookie') { expect(subject).to eq({'cookie' => 'monster'}) }
    end
  end
end
