require 'spec_helper'

RSpec.describe Merkle::Config do
  describe '#initialize' do
    it 'requires element_encoding' do
      expect { described_class.new }.to raise_error(ArgumentError, /element_encoding/)
    end

    it 'rejects an unsupported element_encoding' do
      expect { described_class.new(element_encoding: :utf8) }
        .to raise_error(ArgumentError, 'element_encoding utf8 does not supported.')
    end

    it 'requires element_encoding on the preset configurations' do
      expect { described_class.bitcoin }.to raise_error(ArgumentError, /element_encoding/)
      expect { described_class.taptree }.to raise_error(ArgumentError, /element_encoding/)
      expect(described_class.bitcoin(element_encoding: :hex).hash_type).to eq(:double_sha256)
      expect(described_class.taptree(element_encoding: :hex).branch_tag).to eq('TapBranch')
    end

    it 'carries the tag spec on the config, next to branch_tag' do
      expect(described_class.bitcoin(element_encoding: :hex).leaf_tag).to eq('')
      taptree = described_class.taptree(element_encoding: :hex)
      expect(taptree.leaf_tag).to eq('TapLeaf')
      expect(taptree.branch_tag).to eq('TapBranch')
    end

    it 'rejects a non-string leaf_tag' do
      expect { described_class.new(element_encoding: :hex, leaf_tag: :TapLeaf) }
        .to raise_error(ArgumentError, 'leaf_tag must be string.')
    end
  end

  describe '#encode_element' do
    context 'element_encoding is :hex' do
      let(:config) { described_class.new(element_encoding: :hex) }

      it 'decodes the element' do
        expect(config.encode_element('00ff')).to eq("\x00\xff".b)
      end

      it 'rejects an element that is not an even-length hex string' do
        ['hello', 'abc', ''].each do |element|
          expect { config.encode_element(element) }
            .to raise_error(ArgumentError, 'element must be a hex string.')
        end
      end
    end

    context 'element_encoding is :binary' do
      let(:config) { described_class.new(element_encoding: :binary) }

      it 'keeps the element as bytes' do
        expect(config.encode_element('00ff')).to eq('00ff'.b)
        expect(config.encode_element('hello')).to eq('hello'.b)
      end
    end

    context 'element_encoding is :auto' do
      let(:config) { described_class.new(element_encoding: :auto) }

      it 'decodes an element that looks like hex and keeps the rest as bytes' do
        expect(config.encode_element('00ff')).to eq("\x00\xff".b)
        expect(config.encode_element('hello')).to eq('hello'.b)
      end

      it 'collides an element with its hex representation' do
        # This is why :auto is only for reproducing roots computed by 0.4.0 and earlier.
        expect(config.encode_element('68656c6c6f')).to eq(config.encode_element('hello'))
        expect(config.encode_element('AB')).to eq(config.encode_element('ab'))
      end

      it 'does not pad an odd-length hex string, unlike 0.3.1 and earlier' do
        expect(config.encode_element('abc')).to_not eq(config.encode_element('abc0'))
      end
    end

    it 'gives an element and its hex representation different hashes' do
      # 'hello' and '68656c6c6f' collided while the encoding was guessed.
      hex = described_class.new(element_encoding: :hex)
      binary = described_class.new(element_encoding: :binary)
      expect(hex.tagged_hash(hex.encode_element('68656c6c6f')))
        .to eq(binary.tagged_hash(binary.encode_element('hello')))
      expect(binary.tagged_hash(binary.encode_element('68656c6c6f')))
        .to_not eq(binary.tagged_hash(binary.encode_element('hello')))
    end
  end

  describe '#tagged_hash' do
    let(:config) { described_class.new(element_encoding: :binary, hash_type: :sha256, branch_tag: '') }

    it 'hashes the data as bytes without decoding it' do
      expect(config.tagged_hash('00ff')).to eq(Digest::SHA256.digest('00ff'))
    end

    context 'with UTF-8 input' do
      let(:utf8) { '元氣が一番' }

      it 'returns a 32-byte digest with an empty tag' do
        expect(config.tagged_hash(utf8).bytesize).to eq(32)
      end

      it 'forces binary encoding with a non-empty tag' do
        tagged = described_class.new(element_encoding: :binary, branch_tag: 'MyBranch')
        raw = tagged.tagged_hash(utf8)
        expect(raw.bytesize).to eq(32)
        expect(raw.encoding).to eq(Encoding::ASCII_8BIT)
      end
    end

    it 'accepts a string that is not valid UTF-8' do
      # The encoding used to be probed with a regex, which raised on invalid byte sequences.
      expect { config.tagged_hash("\xff\xfe".force_encoding('UTF-8')) }.not_to raise_error
    end

    context 'double_sha256 path' do
      let(:config) { described_class.new(element_encoding: :hex, hash_type: :double_sha256, branch_tag: 'T') }

      it 'applies SHA256 twice' do
        buf = config.encode_element('deadbeef')
        twice = Digest::SHA256.digest(Digest::SHA256.digest(buf))
        expect(config.tagged_hash(buf, '')).to eq(twice)
      end
    end
  end
end
