require 'spec_helper'

RSpec.describe Merkle::Config do
  describe '#tagged_hash' do
    context 'with hex input' do
      let(:config) { described_class.new(hash_type: :sha256, branch_tag: '') }

      it 'unpacks hex and hashes correctly' do
        hex = '00ff'
        bin = [hex].pack('H*')
        raw = config.tagged_hash(hex)
        expect(raw).to eq(Digest::SHA256.digest(bin))
      end
    end

    context 'with UTF-8 input and empty tag' do
      let(:config) { described_class.new(hash_type: :sha256, branch_tag: '') }
      let(:utf8) { '元氣が一番' }

      it 'does not raise and returns 32-byte digest' do
        expect do
          raw = config.tagged_hash(utf8)
          expect(raw.bytesize).to eq(32)
        end.not_to raise_error
      end
    end

    context 'with UTF-8 input and non-empty branch_tag' do
      let(:config) { described_class.new(hash_type: :sha256, branch_tag: 'MyBranch') }
      let(:utf8) { '元氣が一番' }

      it 'forces binary encoding and hashes without error' do
        expect do
          raw = config.tagged_hash(utf8)
          expect(raw.bytesize).to eq(32)
          expect(raw.encoding).to eq(Encoding::ASCII_8BIT)
        end.not_to raise_error
      end
    end

    context 'double_sha256 path' do
      let(:config) { described_class.new(hash_type: :double_sha256, branch_tag: 'T') }
      let(:data) { 'deadbeef' }

      it 'applies SHA256 twice' do
        buf = [data].pack('H*')
        twice = Digest::SHA256.digest(Digest::SHA256.digest(buf))
        expect(config.tagged_hash(data, '')).to eq(twice)
      end
    end
  end
end
