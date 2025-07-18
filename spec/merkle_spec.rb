# frozen_string_literal: true

RSpec.describe Merkle do
  it "has a version number" do
    expect(Merkle::VERSION).not_to be nil
  end
end
