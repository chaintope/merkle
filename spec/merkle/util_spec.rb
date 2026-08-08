require 'spec_helper'

RSpec.describe Merkle::Util do
  let(:util) { Class.new { include Merkle::Util }.new }

  describe '#hex_string?' do
    it 'accepts an even-length hex string' do
      expect(util.hex_string?('abc0')).to be true
      expect(util.hex_string?('DEADBEEF')).to be true
    end

    it 'rejects an odd-length string' do
      # 'abc' would be padded to "\xAB\xC0" by pack('H*'), colliding with 'abc0'.
      expect(util.hex_string?('abc')).to be false
    end

    it 'rejects a non-hex string' do
      expect(util.hex_string?('hello')).to be false
    end
  end

  describe '#hex_to_bin' do
    it 'does not collide an odd-length string with its zero-padded form' do
      expect(util.hex_to_bin('abc')).to_not eq(util.hex_to_bin('abc0'))
    end
  end

  describe 'leaf collision' do
    let(:config) { Merkle::Config.new }

    it 'gives odd-length elements distinct roots' do
      root_a = Merkle::BinaryTree.from_elements(config: config, elements: %w[abc deadbeef]).compute_root
      root_b = Merkle::BinaryTree.from_elements(config: config, elements: %w[abc0 deadbeef]).compute_root
      expect(root_a).to_not eq(root_b)
    end
  end
end
