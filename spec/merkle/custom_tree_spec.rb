require 'spec_helper'

RSpec.describe Merkle::CustomTree do
  let(:config) { Merkle::Config.new(hash_type: :sha256, sort_hashes: false) }

  describe '#initialize' do
    context 'with nested structure' do
      let(:leaf_a) { config.tagged_hash('A') }
      let(:leaf_b) { config.tagged_hash('B') }
      let(:leaf_c) { config.tagged_hash('C') }
      let(:nested_leaves) { [leaf_a, [leaf_b, leaf_c]] }
      let(:tree) { described_class.new(config: config, leaves: nested_leaves) }

      it 'creates tree with nested structure' do
        expect(tree.leaves).to eq(nested_leaves)
      end

      it 'extracts all leaves correctly' do
        all_leaves = tree.send(:extract_leaves, tree.leaves)
        expect(all_leaves.length).to eq(3)
        expect(all_leaves).to eq([leaf_a, leaf_b, leaf_c])
      end
    end

    context 'with invalid leaf' do
      it 'raises error for non-hex leaf' do
        invalid_leaves = [0, config.tagged_hash('B')]
        expect {
          described_class.new(config: config, leaves: invalid_leaves)
        }.to raise_error(ArgumentError, /leaf hash must be string./)
      end
    end
    
    context 'with invalid binary tree structure' do
      it 'raises error for node with 3 children' do
        leaf_a = config.tagged_hash('A')
        leaf_b = config.tagged_hash('B')
        leaf_c = config.tagged_hash('C')
        invalid_structure = [leaf_a, leaf_b, leaf_c]  # 3 children at root
        
        expect {
          described_class.new(config: config, leaves: invalid_structure)
        }.to raise_error(ArgumentError, /Binary tree nodes can have at most 2 children, got 3/)
      end
      
      it 'raises error for node with 4 children' do
        leaf_a = config.tagged_hash('A')
        leaf_b = config.tagged_hash('B')
        leaf_c = config.tagged_hash('C')
        leaf_d = config.tagged_hash('D')
        invalid_structure = [leaf_a, leaf_b, leaf_c, leaf_d]  # 4 children at root
        
        expect {
          described_class.new(config: config, leaves: invalid_structure)
        }.to raise_error(ArgumentError, /Binary tree nodes can have at most 2 children, got 4/)
      end
      
      it 'raises error for nested node with 3 children' do
        leaf_a = config.tagged_hash('A')
        leaf_b = config.tagged_hash('B')
        leaf_c = config.tagged_hash('C')
        leaf_d = config.tagged_hash('D')
        # Root has 2 children, but left subtree has 3 children
        invalid_structure = [[leaf_a, leaf_b, leaf_c], leaf_d]
        
        expect {
          described_class.new(config: config, leaves: invalid_structure)
        }.to raise_error(ArgumentError, /Binary tree nodes can have at most 2 children, got 3/)
      end
      
      it 'allows valid binary tree with exactly 2 children' do
        leaf_a = config.tagged_hash('A')
        leaf_b = config.tagged_hash('B')
        valid_structure = [leaf_a, leaf_b]  # Exactly 2 children
        
        expect {
          described_class.new(config: config, leaves: valid_structure)
        }.not_to raise_error
      end
      
      it 'allows node with 1 child' do
        leaf_a = config.tagged_hash('A')
        valid_structure = [leaf_a]  # Single child is allowed
        
        expect {
          described_class.new(config: config, leaves: valid_structure)
        }.not_to raise_error
      end
      
      it 'raises error for empty array' do
        invalid_structure = []  # Empty array not allowed
        
        expect {
          described_class.new(config: config, leaves: invalid_structure)
        }.to raise_error(ArgumentError, /Binary tree nodes cannot be empty/)
      end
    end
  end

  describe '#compute_root' do
    context 'with structure: A, (B, C), (D, E), F' do
      let(:leaf_a) { config.tagged_hash('A') }
      let(:leaf_b) { config.tagged_hash('B') }
      let(:leaf_c) { config.tagged_hash('C') }
      let(:leaf_d) { config.tagged_hash('D') }
      let(:leaf_e) { config.tagged_hash('E') }
      let(:leaf_f) { config.tagged_hash('F') }
      let(:nested_leaves) { [[[leaf_a, [leaf_b, leaf_c]], [leaf_d, leaf_e]], leaf_f] }
      let(:tree) { described_class.new(config: config, leaves: nested_leaves) }

      it 'computes root according to structure' do
        # Expected computation:
        # h(B,C) = hash(B || C)
        # h(D,E) = hash(D || E)
        # root = hash(A || h(B,C) || h(D,E) || F)
        
        h_bc = config.tagged_hash(leaf_b + leaf_c)
        h_a_bc = config.tagged_hash(leaf_a + h_bc)
        h_de = config.tagged_hash(leaf_d + leaf_e)
        h_left = config.tagged_hash(h_a_bc + h_de)
        expected_root = config.tagged_hash(h_left + leaf_f)
        
        expect(tree.compute_root).to eq(expected_root.unpack1('H*'))
      end
    end

    context 'with nested structure: ((A, B), (C, (D, E)), F)' do
      let(:leaf_a) { config.tagged_hash('A') }
      let(:leaf_b) { config.tagged_hash('B') }
      let(:leaf_c) { config.tagged_hash('C') }
      let(:leaf_d) { config.tagged_hash('D') }
      let(:leaf_e) { config.tagged_hash('E') }
      let(:leaf_f) { config.tagged_hash('F') }
      let(:nested_leaves) { [[leaf_a, leaf_b], [leaf_c, [leaf_d, leaf_e]]] }
      let(:tree) { described_class.new(config: config, leaves: nested_leaves) }

      it 'computes root with nested groups' do
        # Expected computation:
        # h(A,B) = hash(A || B)
        # h(D,E) = hash(D || E)
        # h(C,h(D,E)) = hash(C || h(D,E))
        # root = hash(h(A,B) || h(C,h(D,E)) || F)
        
        h_ab = config.tagged_hash(leaf_a + leaf_b)
        h_de = config.tagged_hash(leaf_d + leaf_e)
        h_c_de = config.tagged_hash(leaf_c + h_de)
        expected_root = config.tagged_hash(h_ab + h_c_de)
        
        expect(tree.compute_root).to eq(expected_root.unpack1('H*'))
      end
    end

    context 'with sorted hashes' do
      let(:config) { Merkle::Config.new(hash_type: :sha256, sort_hashes: true) }
      let(:leaf_a) { config.tagged_hash('A') }
      let(:leaf_b) { config.tagged_hash('B') }
      let(:nested_leaves) { [leaf_b, leaf_a] }  # B, A
      let(:tree) { described_class.new(config: config, leaves: nested_leaves) }

      it 'sorts child hashes before combining' do
        # With sort_hashes: true, should sort [B, A] to [A, B]
        # leaf_a: c19a797fa1fd590cd2e5b42d1cf5f246e29b91684e2f87404b81dc345c7a56a0
        # leaf_b: f4f97c88c409dcf3789b5b518da3f7d266c488066e97a606e38a150779880735

        sorted_root = config.tagged_hash(leaf_a + leaf_b)
        expect(tree.compute_root).to eq(sorted_root.unpack1('H*'))
      end
    end
  end

  describe '.from_elements' do
    it 'creates tree from nested elements' do
      nested_elements = [['A', ['B', 'C']], 'D']  # Binary tree structure
      tree = described_class.from_elements(config: config, elements: nested_elements)
      
      # Check structure is preserved: [[A, [B, C]], D]
      expect(tree.leaves[0]).to be_an(Array)  # Left subtree
      expect(tree.leaves[0][0]).to eq(config.tagged_hash('A').unpack1('H*'))
      expect(tree.leaves[0][1]).to be_an(Array)
      expect(tree.leaves[0][1][0]).to eq(config.tagged_hash('B').unpack1('H*'))
      expect(tree.leaves[0][1][1]).to eq(config.tagged_hash('C').unpack1('H*'))
      expect(tree.leaves[1]).to eq(config.tagged_hash('D').unpack1('H*'))  # Right leaf
    end

    it 'uses leaf tag when hashing' do
      tag = 'test_tag'
      nested_elements = ['A', ['B', 'C']]
      tree = described_class.from_elements(config: config, elements: nested_elements, leaf_tag: tag)
      
      expect(tree.leaves[0]).to eq(config.tagged_hash('A', tag).unpack1('H*'))
      expect(tree.leaves[1][0]).to eq(config.tagged_hash('B', tag).unpack1('H*'))
      expect(tree.leaves[1][1]).to eq(config.tagged_hash('C', tag).unpack1('H*'))
    end
  end

  describe '#generate_proof' do
    let(:leaf_a) { config.tagged_hash('A') }
    let(:leaf_b) { config.tagged_hash('B') }
    let(:leaf_c) { config.tagged_hash('C') }
    let(:leaf_d) { config.tagged_hash('D') }
    let(:nested_leaves) { [[leaf_a, [leaf_b, leaf_c]], leaf_d] }
    let(:tree) { described_class.new(config: config, leaves: nested_leaves) }

    it 'creates proof objects' do
      # Test with binary tree structure: [[A, [B, C]], D]
      # Structure: root has left=([A, [B, C]]) and right=D
      # For leaf A: path is root -> left -> left
      
      proof = tree.generate_proof(0)  # leaf A
      expect(proof.leaf).to eq(leaf_a)
      
      # Expected computation:
      # h(B,C) = hash(B || C)
      # h(A, h(B,C)) = hash(A || h(B,C))
      # root = hash(h(A, h(B,C)) || D)
      
      bc = config.tagged_hash(leaf_b + leaf_c)
      a_bc = config.tagged_hash(leaf_a + bc)
      expected_root = config.tagged_hash(a_bc + leaf_d)
      
      expect(proof.root).to eq(expected_root.unpack1('H*'))
      expect(proof.valid?).to be true
      expect(proof.directions).to eq([1, 1])
      expect(proof.siblings).to eq([bc.unpack1('H*'), leaf_d.unpack1('H*')])
    end
  end

  describe 'example usage' do
    let(:leaf_tag) { 'user' }
    it 'demonstrates creating a custom tree structure' do
      # Create elements
      elements = %w[Alice Bob Charlie David Eve Frank]
      
      # Define binary tree structure: [[[Alice, [Bob, Charlie]], [David, Eve]], Frank]
      nested_elements = [[[elements[0], [elements[1], elements[2]]], [elements[3], elements[4]]], elements[5]]
      
      # Create tree
      tree = Merkle::CustomTree.from_elements(
        config: config,
        elements: nested_elements,
        leaf_tag: leaf_tag
      )
      
      # Compute root
      root = tree.compute_root
      expect(root).to be_a(String)
      
      # Generate proof for Charlie
      proof = tree.generate_proof(2)  # Charlie is at index 2
      expect(proof.leaf).to eq(config.tagged_hash('Charlie', leaf_tag).unpack1('H*'))
      expect(proof.valid?).to be true
      d = config.tagged_hash(elements[3], leaf_tag)
      e = config.tagged_hash(elements[4], leaf_tag)
      de = config.tagged_hash(d + e)
      f = config.tagged_hash(elements[5], leaf_tag)
      expect(proof.siblings).to eq([
                                     config.tagged_hash(elements[1], leaf_tag).unpack1('H*'),
                                     config.tagged_hash(elements[0], leaf_tag).unpack1('H*'),
                                     de.unpack1('H*'),
                                     f.unpack1('H*')
                                   ])
      expect(proof.directions).to eq([0, 0, 1, 1])
    end
  end
end