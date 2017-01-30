require 'spec_helper'

describe Webmachine::Response do

  it "should have sane default values" do
    expect(subject.code).to eq(200)
    expect(subject.is_redirect?).to be(false)
    expect(subject.headers).to be_empty
  end

  describe "a redirected response" do
    let(:redirect_url) { "/" }

    before(:each) { subject.redirect_to redirect_url }

    its(:is_redirect?) { should be(true) }

    it "should have a proper Location header" do
      expect(subject.headers["Location"]).to eq(redirect_url)
    end
  end

  describe "setting a cookie" do
    let(:cookie) { "monster" }
    let(:cookie_value) { "mash" }

    before(:each) { subject.set_cookie(cookie, cookie_value) }

    it "should have a proper Set-Cookie header" do
      expect(subject.headers["Set-Cookie"]).to include "monster=mash"
    end

    describe "setting multiple cookies" do
      let(:cookie2) { "rodeo" }
      let(:cookie2_value) { "clown" }
      let(:cookie3) {"color"}
      let(:cookie3_value) {"blue"}
      before(:each) do 
        subject.set_cookie(cookie2, cookie2_value)
        subject.set_cookie(cookie3, cookie3_value)
      end

      it "should have a proper Set-Cookie header" do
        expect(subject.headers["Set-Cookie"]).to be_a Array
        expect(subject.headers["Set-Cookie"]).to include "rodeo=clown"
        expect(subject.headers["Set-Cookie"]).to include "monster=mash"
        expect(subject.headers["Set-Cookie"]).to include "color=blue"
      end
    end
  end
end
