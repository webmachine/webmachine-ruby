require 'spec_helper'

describe Falsey do
  specify { (Falsey.=== false).should be_true }
  specify { (Falsey.=== nil).should be_true }
  specify { (Falsey.=== true).should be_false }
  specify { (Falsey.=== []).should be_false }
end