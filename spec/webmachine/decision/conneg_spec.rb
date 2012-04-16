require 'spec_helper'

describe Webmachine::Decision::Conneg do
  let(:request) { Webmachine::Request.new("GET", URI.parse("http://localhost:8080/"), Webmachine::Headers["accept" => "*/*"], "") }
  let(:response) { Webmachine::Response.new }
  let(:resource) do
    Class.new(Webmachine::Resource) do
      def to_html; "hello world!"; end
    end
  end

  subject do
    Webmachine::Decision::FSM.new(resource, request, response)
  end

  context "choosing a media type" do
    it "should not choose a type when none are provided" do
      subject.choose_media_type([], "*/*").should be_nil
    end

    it "should not choose a type when none are acceptable" do
      subject.choose_media_type(["text/html"], "application/json").should be_nil
    end

    it "should choose the first acceptable type" do
      subject.choose_media_type(["text/html", "application/xml"],
                                "application/xml, text/html, */*").should == "application/xml"
    end

    it "should choose the type that matches closest when matching subparams" do
      subject.choose_media_type(["text/html",
                                 ["text/html", {"charset" => "iso8859-1"}]],
                                "text/html;charset=iso8859-1, application/xml").
        should == "text/html;charset=iso8859-1"
    end
    
    it "should choose a type more specific than requested when an exact match is not present" do
      subject.choose_media_type(["application/json;v=3;foo=bar", "application/json;v=2"],
                                "text/html, application/json").
        should == "application/json;v=3;foo=bar"
    end


    it "should choose the preferred type over less-preferred types" do
      subject.choose_media_type(["text/html", "application/xml"],
                                "application/xml;q=0.7, text/html, */*").should == "text/html"

    end

    it "should raise an exception when a media-type is improperly formatted" do
      expect {
        subject.choose_media_type(["text/html", "application/xml"],
                                  "bah;")
      }.to raise_error(Webmachine::MalformedRequest)
    end
  end

  context "choosing an encoding" do
    it "should not set the encoding when none are provided" do
      subject.choose_encoding({}, "identity, gzip")
      subject.metadata['Content-Encoding'].should be_nil
      subject.response.headers['Content-Encoding'].should be_nil
    end

    it "should not set the Content-Encoding header when it is identity" do
      subject.choose_encoding({"gzip"=> :encode_gzip, "identity" => :encode_identity}, "identity")
      subject.metadata['Content-Encoding'].should == 'identity'
      response.headers['Content-Encoding'].should be_nil
    end

    it "should choose the first acceptable encoding" do
      subject.choose_encoding({"gzip" => :encode_gzip}, "identity, gzip")
      subject.metadata['Content-Encoding'].should == 'gzip'
      response.headers['Content-Encoding'].should == 'gzip'
    end

    it "should choose the first acceptable encoding" \
       ", even when no white space after comma" do
      subject.choose_encoding({"gzip" => :encode_gzip}, "identity,gzip")
      subject.metadata['Content-Encoding'].should == 'gzip'
      response.headers['Content-Encoding'].should == 'gzip'
    end

    it "should choose the preferred encoding over less-preferred encodings" do
      subject.choose_encoding({"gzip" => :encode_gzip, "identity" => :encode_identity}, "gzip, identity;q=0.7")
      subject.metadata['Content-Encoding'].should == 'gzip'
      response.headers['Content-Encoding'].should == 'gzip'
    end

    it "should not set the encoding if none are acceptable" do
      subject.choose_encoding({"gzip" => :encode_gzip}, "identity")
      subject.metadata['Content-Encoding'].should be_nil
      response.headers['Content-Encoding'].should be_nil
    end
  end

  context "choosing a charset" do
    it "should not set the charset when none are provided" do
      subject.choose_charset([], "ISO-8859-1")
      subject.metadata['Charset'].should be_nil
    end

    it "should choose the first acceptable charset" do
      subject.choose_charset([["UTF-8", :to_utf8],["US-ASCII", :to_ascii]], "US-ASCII, UTF-8")
      subject.metadata['Charset'].should == "US-ASCII"
    end

    it "should choose the preferred charset over less-preferred charsets" do
      subject.choose_charset([["UTF-8", :to_utf8],["US-ASCII", :to_ascii]], "US-ASCII;q=0.7, UTF-8")
      subject.metadata['Charset'].should == "UTF-8"
    end

    it "should not set the charset if none are acceptable" do
      subject.choose_charset([["UTF-8", :to_utf8],["US-ASCII", :to_ascii]], "ISO-8859-1")
      subject.metadata['Charset'].should be_nil
    end

    it "should choose a charset case-insensitively" do
      subject.choose_charset([["UtF-8", :to_utf8],["US-ASCII", :to_ascii]], "iso-8859-1, utf-8")
      subject.metadata['Charset'].should == "utf-8"
    end
  end

  context "choosing a language" do
    it "should not set the language when none are provided" do
      subject.choose_language([], "en")
      subject.metadata['Language'].should be_nil
    end

    it "should choose the first acceptable language" do
      subject.choose_language(['en', 'en-US', 'es'], "en-US, es")
      subject.metadata['Language'].should == "en-US"
      response.headers['Content-Language'].should == "en-US"
    end

    it "should choose the preferred language over less-preferred languages" do
      subject.choose_language(['en', 'en-US', 'es'], "en-US;q=0.6, es")
      subject.metadata['Language'].should == "es"
      response.headers['Content-Language'].should == "es"
    end

    it "should select the first language if all are acceptable" do
      subject.choose_language(['en', 'fr', 'es'], "*")
      subject.metadata['Language'].should == "en"
      response.headers['Content-Language'].should == "en"
    end

    it "should select the closest acceptable language when an exact match is not available" do
      subject.choose_language(['en-US', 'es'], "en, fr")
      subject.metadata['Language'].should == 'en-US'
      response.headers['Content-Language'].should == 'en-US'
    end

    it "should not set the language if none are acceptable" do
      subject.choose_language(['en'], 'es')
      subject.metadata['Language'].should be_nil
      response.headers.should_not include('Content-Language')
    end

    it "should choose a language case-insensitively" do
      subject.choose_language(['en-US', 'ZH'], 'zh-ch, EN')
      subject.metadata['Language'].should == 'en-US'
      response.headers['Content-Language'].should == 'en-US'
    end
  end
end
