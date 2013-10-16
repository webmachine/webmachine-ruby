require 'spec_helper'

describe Webmachine::CacheControl do
  #Per http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.9
  #Cache-Control   = "Cache-Control" ":" 1#cache-directive"
  #    cache-request-directive =
  #       "no-cache"
  #     | "no-store"
  #     | "max-age" "=" delta-seconds
  #     | "max-stale" [ "=" delta-seconds ]
  #     | "min-fresh" "=" delta-seconds
  #     | "no-transform"
  #     | "only-if-cached"
  #     | cache-extension
  #
  # cache-response-directive =
  #       "public"
  #     | "private" [ "=" <"> 1#field-name <"> ]
  #     | "no-cache" [ "=" <"> 1#field-name <"> ]
  #     | "no-store"
  #     | "no-transform"
  #     | "must-revalidate"
  #     | "proxy-revalidate"
  #     | "max-age" "=" delta-seconds
  #     | "s-maxage" "=" delta-seconds
  #     | cache-extension
  # cache-extension = token [ "=" ( token | quoted-string ) ]"

  describe "Creating a cache-control header" do
    let :directives do
      {}
    end

    subject(:cache_control) do
      Webmachine::CacheControl.new(directives)
    end

    describe "created with empty directives" do
      it "should render as an empty string" do
        cache_control.to_s.should == ""
      end
    end

    describe "with invalid directives" do
      let :directives do
        { :cookie => "monster"}
      end

      it "should raise error" do
        expect do
          cache_control
        end.to raise_error(ArgumentError)
      end
    end

    describe "updated with string names" do
      before :each do
        cache_control["no-store"] = true
      end

      it "should render simple header value" do
        cache_control.to_s.should == "no-store"
      end
    end

    describe "with reasonable directives" do
      let :directives do
        {
          :no_store => true,
          :no_transform => true,
          :proxy_revalidate => true,
          :no_cache => ["Vary", "Cookies"],
          :max_age => 3600,
          :extensions => {:community => "basho"}
        }
      end

      its(:no_store){ should == true }
      its(:no_transform){ should == true }
      its(:proxy_revalidate){ should == true }
      its(:no_cache){ should include "Vary" }
      its(:no_cache){ should include "Cookies" }
      its(:max_age){ should == 3600 }
      its(:extensions){ should == {:community => "basho"}}

      its(:private){ should == nil }
      its(:public){ should == nil }
      its(:must_revalidate){ should == nil}

      it "should include directives in string version" do
        string = cache_control.to_s

        string.should =~ /\A[^,]*(,[^,]*){6}[^,]*\Z/ #four comma, five directives
        string.should include "no-store"
        string.should include "no-transform"
        string.should include "proxy-revalidate"
        string.should include "max-age=3600"
        string.should include 'community="basho"'
      end
    end
  end

  describe "Parsing a Cache-control header" do
    let :string do
      'no-store, Proxy-Revalidate, MAX-AGE = 24000, unrecognized=token, basho = thing, String = "string", no-cache="Vary,Accept"'
    end

    subject :cache_control do
      Webmachine::CacheControl.parse(string, [:thing])
    end

    its(:no_store){ should == true}
    its(:proxy_revalidate){ should == true }
    its(:max_age){ should == 24000 }
    its(:extensions){ should == {"unrecognized" => "token", "basho" => :thing, "string" => "string"}}
    its(:no_cache){ should include("Vary","Accept") }
  end
end
