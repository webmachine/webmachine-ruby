require 'spec_helper'

describe Webmachine::Response do

  it "should have sane default values" do
    subject.code.should == 200
    subject.is_redirect?.should be_false
    subject.headers.should be_empty
  end

  describe "a redirected response" do
    let(:redirect_url) { "/" }

    before(:all) { subject.redirect_to redirect_url }

    its(:is_redirect?) { should be_true }

    it "should have a proper Location header" do
      subject.headers["Location"].should == redirect_url
    end
  end

  describe "setting Cache-Control" do
    describe "with a Hash" do
      before(:all){ subject.set_cache_control(:no_store => true) }

      it "should have a proper Cache-Control header" do
        subject.headers["Cache-Control"].should include "no-store"
      end
    end

    describe "with an empty string" do
      before(:all){ subject.set_cache_control("") }

      it "should not have a Cache-Control header" do
        subject.headers["Cache-Control"].should be_nil
      end
    end
  end

  describe "setting a cookie" do
    let(:cookie) { "monster" }
    let(:cookie_value) { "mash" }

    before(:all) { subject.set_cookie(cookie, cookie_value) }

    it "should have a proper Set-Cookie header" do
      subject.headers["Set-Cookie"].should include "monster=mash";
    end

    describe "setting multiple cookies" do
      let(:cookie2) { "rodeo" }
      let(:cookie2_value) { "clown" }
      before(:all) { subject.set_cookie(cookie2, cookie2_value) }

      it "should have a proper Set-Cookie header" do
        subject.headers["Set-Cookie"].should be_a Array
        subject.headers["Set-Cookie"].should include "rodeo=clown"
        subject.headers["Set-Cookie"].should include "monster=mash"
      end
    end
  end
end
