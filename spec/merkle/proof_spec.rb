require 'spec_helper'

RSpec.describe Merkle::Proof do
  let(:elements) { %w[hello world merkle tree] }

  describe '#initialize' do
    context 'sort_hashes is true' do
      let(:config) { Merkle::Config.new(element_encoding: :binary) }
      let(:proof) { Merkle::BinaryTree.from_elements(config: config, elements: elements).generate_proof(0) }
      let(:args) { { config: config, root: proof.root, leaf: proof.leaf, siblings: proof.siblings } }

      it 'rejects siblings that is not an Array' do
        expect { described_class.new(**args.merge(siblings: nil)) }
          .to raise_error(ArgumentError, 'siblings must be an Array')
        expect { described_class.new(**args.merge(siblings: proof.siblings.first)) }
          .to raise_error(ArgumentError, 'siblings must be an Array')
      end

      it 'rejects a sibling that is not a string' do
        expect { described_class.new(**args.merge(siblings: [123])) }
          .to raise_error(ArgumentError, 'sibling must be string')
      end

      it 'rejects a sibling that is not a 64-character hex string' do
        expect { described_class.new(**args.merge(siblings: ['zz'])) }
          .to raise_error(ArgumentError, 'sibling must be a 64-character hex string')
        expect { described_class.new(**args.merge(siblings: ['00' * 31])) }
          .to raise_error(ArgumentError, 'sibling must be a 64-character hex string')
      end

      it 'rejects more siblings than MAX_SIBLINGS' do
        siblings = ['00' * 32] * (Merkle::Proof::MAX_SIBLINGS + 1)
        expect { described_class.new(**args.merge(siblings: siblings)) }
          .to raise_error(ArgumentError, "siblings must not exceed #{Merkle::Proof::MAX_SIBLINGS} elements")
      end

      it 'accepts a proof as deep as a BIP341 script tree can be' do
        # A control block carries at most 128 path elements.
        expect(Merkle::Proof::MAX_SIBLINGS).to eq(128)
        siblings = ['00' * 32] * 128
        expect { described_class.new(**args.merge(siblings: siblings)) }.not_to raise_error
      end

      it 'verifies a root written in upper case' do
        # A node hash is accepted in either case, so verification must not depend on it.
        expect(described_class.new(**args.merge(root: proof.root.upcase)).valid?).to be true
        expect(described_class.new(**args.merge(leaf: proof.leaf.upcase)).valid?).to be true
        upper = proof.siblings.map(&:upcase)
        expect(described_class.new(**args.merge(siblings: upper)).valid?).to be true
      end

      it 'rejects directions' do
        expect { described_class.new(**args.merge(directions: [0, 1])) }
          .to raise_error(ArgumentError, 'No directions are required because sorted_hash is enabled')
      end
    end

    context 'sort_hashes is false' do
      let(:config) { Merkle::Config.new(element_encoding: :binary, sort_hashes: false) }
      let(:proof) { Merkle::BinaryTree.from_elements(config: config, elements: elements).generate_proof(1) }
      let(:args) do
        { config: config, root: proof.root, leaf: proof.leaf, siblings: proof.siblings, directions: proof.directions }
      end

      it 'accepts a proof whose directions match its siblings' do
        expect(described_class.new(**args).valid?).to be true
      end

      it 'rejects directions shorter or longer than siblings' do
        [[], [0], [0, 1, 1]].each do |directions|
          expect { described_class.new(**args.merge(directions: directions)) }
            .to raise_error(ArgumentError, 'directions must have the same length as siblings')
        end
      end

      it 'rejects a direction other than 0 or 1' do
        expect { described_class.new(**args.merge(directions: [0, 2])) }
          .to raise_error(ArgumentError, 'direction must be 0 or 1')
      end
    end
  end
end
