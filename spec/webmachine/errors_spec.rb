require 'spec_helper'

describe "Webmachine errors" do
  describe ".render_error" do
    it "sets the given response code on the response object" do
      req = double('request', :method => 'GET').as_null_object
      res = Webmachine::Response.new

      Webmachine.render_error(404, req, res)
      res.code.should == 404
    end
  end
end
