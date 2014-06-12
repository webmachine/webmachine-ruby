require 'spec_helper'

describe Webmachine::Decision::Falsey do
  specify { (described_class.=== false).should be(true) }
  specify { (described_class.=== nil).should be(true) }
  specify { (described_class.=== true).should be(false) }
  specify { (described_class.=== []).should be(false) }
end
