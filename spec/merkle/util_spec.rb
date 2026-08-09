require 'spec_helper'

RSpec.describe Merkle::Util do
  let(:util) { Class.new { include Merkle::Util }.new }
  let(:hash_hex) { 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3' }

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

    it 'rejects a string whose encoding the regex cannot match' do
      # Matching the string itself raised Encoding::CompatibilityError or ArgumentError from the
      # regex, which reached callers of Config#encode_element as an unrelated failure.
      expect(util.hex_string?('abcd'.encode('UTF-16LE'))).to be false
      expect(util.hex_string?((+"\xff\xfe").force_encoding('UTF-8'))).to be false
    end
  end

  describe '#decode_hash' do
    it 'decodes a node hash' do
      expect(util.decode_hash(hash_hex)).to eq([hash_hex].pack('H*'))
    end

    it 'rejects anything that is not a 64-character hex string' do
      # Variable-length node hashes make the concatenation in an internal node ambiguous:
      # ['aa', 'bbcc'] and ['aabb', 'cc'] would otherwise produce the same root.
      ['aa', hash_hex + '00', 'z' * 64, ''].each do |value|
        expect { util.decode_hash(value) }
          .to raise_error(ArgumentError, 'hash must be a 64-character hex string')
      end
    end

    it 'rejects a non-string' do
      expect { util.decode_hash(nil) }.to raise_error(ArgumentError, 'hash must be string')
    end

    it 'rejects a string holding invalid UTF-8 bytes' do
      # Matching the string itself would raise 'invalid byte sequence in UTF-8' from the regex.
      expect { util.decode_hash(("\xff" * 64).force_encoding('UTF-8')) }
        .to raise_error(ArgumentError, 'hash must be a 64-character hex string')
    end
  end

  describe 'leaf collision' do
    it 'gives odd-length elements distinct roots' do
      config = Merkle::Config.new(element_encoding: :binary)
      root_a = Merkle::BinaryTree.from_elements(config: config, elements: %w[abc deadbeef]).compute_root
      root_b = Merkle::BinaryTree.from_elements(config: config, elements: %w[abc0 deadbeef]).compute_root
      expect(root_a).to_not eq(root_b)
    end
  end

  describe 'leaf validation' do
    let(:config) { Merkle::Config.new(element_encoding: :hex) }

    it 'rejects leaves that are not node hashes' do
      expect { Merkle::BinaryTree.new(config: config, leaves: %w[aa bbcc]) }
        .to raise_error(ArgumentError, 'hash must be a 64-character hex string')
    end
  end
end
