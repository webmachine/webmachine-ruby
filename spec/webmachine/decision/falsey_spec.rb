require 'spec_helper'

describe Webmachine::Decision::Falsey do
  specify { (described_class.=== false).should be_true }
  specify { (described_class.=== nil).should be_true }
  specify { (described_class.=== true).should be_false }
  specify { (described_class.=== []).should be_false }
end
