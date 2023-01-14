require 'spec_helper'

describe Webmachine::Decision::Falsey do
  specify { expect(described_class === false).to be(true) }
  specify { expect(described_class === nil).to be(true) }
  specify { expect(described_class === true).to be(false) }
  specify { expect(described_class === []).to be(false) }
end
