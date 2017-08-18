require 'spec_helper'

describe Webmachine::Decision::Conneg do
  include_context "default resource"

  subject do
    Webmachine::Decision::FSM.new(resource, request, response)
  end

  context "choosing a media type" do
    it "should not choose a type when none are provided" do
      expect(subject.choose_media_type([], "*/*")).to be_nil
    end

    it "should not choose a type when none are acceptable" do
      expect(subject.choose_media_type(["text/html"], "application/json")).to be_nil
    end

    it "should choose the first acceptable type" do
      expect(subject.choose_media_type(["text/html", "application/xml"],
                                "application/xml, text/html, */*")).to eq("application/xml")
    end

    it "should choose the type that matches closest when matching subparams" do
      expect(subject.choose_media_type(["text/html",
                                 ["text/html", {"charset" => "iso8859-1"}]],
                                "text/html;charset=iso8859-1, application/xml")).
        to eq("text/html;charset=iso8859-1")
    end

    it "should choose a type more specific than requested when an exact match is not present" do
      expect(subject.choose_media_type(["application/json;v=3;foo=bar", "application/json;v=2"],
                                "text/html, application/json")).
        to eq("application/json;v=3;foo=bar")
    end


    it "should choose the preferred type over less-preferred types" do
      expect(subject.choose_media_type(["text/html", "application/xml"],
                                "application/xml;q=0.7, text/html, */*")).to eq("text/html")

    end

    it "should raise an error when a media-type is improperly formatted" do
      expect {
        subject.choose_media_type(["text/html", "application/xml"],
                                  "bah;")
      }.to raise_error(Webmachine::MalformedRequest)
    end

    it "should choose a type when more than one accept header is present" do
      expect(subject.choose_media_type(["text/html"],
                                ["text/html", "text/plain"])).to eq("text/html")

    end
  end

  context "choosing an encoding" do
    it "should not set the encoding when none are provided" do
      subject.choose_encoding({}, "identity, gzip")
      expect(subject.metadata['Content-Encoding']).to be_nil
      expect(subject.response.headers['Content-Encoding']).to be_nil
    end

    it "should not set the Content-Encoding header when it is identity" do
      subject.choose_encoding({"gzip"=> :encode_gzip, "identity" => :encode_identity}, "identity")
      expect(subject.metadata['Content-Encoding']).to eq('identity')
      expect(response.headers['Content-Encoding']).to be_nil
    end

    it "should choose the first acceptable encoding" do
      subject.choose_encoding({"gzip" => :encode_gzip}, "identity, gzip")
      expect(subject.metadata['Content-Encoding']).to eq('gzip')
      expect(response.headers['Content-Encoding']).to eq('gzip')
    end

    it "should choose the first acceptable encoding" \
    ", even when no white space after comma" do
      subject.choose_encoding({"gzip" => :encode_gzip}, "identity,gzip")
      expect(subject.metadata['Content-Encoding']).to eq('gzip')
      expect(response.headers['Content-Encoding']).to eq('gzip')
    end

    it "should choose the preferred encoding over less-preferred encodings" do
      subject.choose_encoding({"gzip" => :encode_gzip, "identity" => :encode_identity}, "gzip, identity;q=0.7")
      expect(subject.metadata['Content-Encoding']).to eq('gzip')
      expect(response.headers['Content-Encoding']).to eq('gzip')
    end

    it "should not set the encoding if none are acceptable" do
      subject.choose_encoding({"gzip" => :encode_gzip}, "identity")
      expect(subject.metadata['Content-Encoding']).to be_nil
      expect(response.headers['Content-Encoding']).to be_nil
    end
  end

  context "choosing a charset" do
    it "should not set the charset when none are provided" do
      subject.choose_charset([], "ISO-8859-1")
      expect(subject.metadata['Charset']).to be_nil
    end

    it "should choose the first acceptable charset" do
      subject.choose_charset([["UTF-8", :to_utf8],["US-ASCII", :to_ascii]], "US-ASCII, UTF-8")
      expect(subject.metadata['Charset']).to eq("US-ASCII")
    end

    it "should choose the preferred charset over less-preferred charsets" do
      subject.choose_charset([["UTF-8", :to_utf8],["US-ASCII", :to_ascii]], "US-ASCII;q=0.7, UTF-8")
      expect(subject.metadata['Charset']).to eq("UTF-8")
    end

    it "should not set the charset if none are acceptable" do
      subject.choose_charset([["UTF-8", :to_utf8],["US-ASCII", :to_ascii]], "ISO-8859-1")
      expect(subject.metadata['Charset']).to be_nil
    end

    it "should choose a charset case-insensitively" do
      subject.choose_charset([["UtF-8", :to_utf8],["US-ASCII", :to_ascii]], "iso-8859-1, utf-8")
      expect(subject.metadata['Charset']).to eq("utf-8")
    end
  end

  context "choosing a language" do
    it "should not set the language when none are provided" do
      subject.choose_language([], "en")
      expect(subject.metadata['Language']).to be_nil
    end

    it "should choose the first acceptable language" do
      subject.choose_language(['en', 'en-US', 'es'], "en-US, es")
      expect(subject.metadata['Language']).to eq("en-US")
      expect(response.headers['Content-Language']).to eq("en-US")
    end

    it "should choose the preferred language over less-preferred languages" do
      subject.choose_language(['en', 'en-US', 'es'], "en-US;q=0.6, es")
      expect(subject.metadata['Language']).to eq("es")
      expect(response.headers['Content-Language']).to eq("es")
    end

    it "should select the first language if all are acceptable" do
      subject.choose_language(['en', 'fr', 'es'], "*")
      expect(subject.metadata['Language']).to eq("en")
      expect(response.headers['Content-Language']).to eq("en")
    end

    it "should select the closest acceptable language when an exact match is not available" do
      subject.choose_language(['en-US', 'es'], "en, fr")
      expect(subject.metadata['Language']).to eq('en-US')
      expect(response.headers['Content-Language']).to eq('en-US')
    end

    it "should not set the language if none are acceptable" do
      subject.choose_language(['en'], 'es')
      expect(subject.metadata['Language']).to be_nil
      expect(response.headers).not_to include('Content-Language')
    end

    it "should choose a language case-insensitively" do
      subject.choose_language(['en-US', 'ZH'], 'zh-ch, EN')
      expect(subject.metadata['Language']).to eq('en-US')
      expect(response.headers['Content-Language']).to eq('en-US')
    end
  end
end
