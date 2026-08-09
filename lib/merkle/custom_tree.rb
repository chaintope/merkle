module Merkle
  # Custom Merkle tree implementation that allows specifying the tree structure
  # Example: [leaf_A, [leaf_B, leaf_C], [leaf_D, leaf_E], leaf_F]
  class CustomTree < AbstractTree

    # Constructor
    # @param [Merkle::Config] config Configuration for merkle tree.
    # @param [Array] leaves A nested array representing the tree structure.
    #                       Each element can be a leaf hash (hex string) or an array of child nodes.
    def initialize(config:, leaves:)
      super(config: config, leaves: leaves)
    end

    # Create tree from elements with custom structure
    # @param [Merkle::Config] config Configuration for merkle tree.
    # @param [Array] elements A nested array of elements that will be hashed to become leaves.
    # The tag used for the leaf hash comes from +config.leaf_tag+.
    def self.from_elements(config:, elements:)
      raise ArgumentError, 'config must be Merkle::Config' unless config.is_a?(Merkle::Config)
      raise ArgumentError, 'elements must be Array' unless elements.is_a?(Array)

      # Convert elements to hashes while preserving structure
      hashed_structure = convert_elements_to_hashes(elements, config)

      self.new(config: config, leaves: hashed_structure)
    end

    # Compute merkle root using custom structure
    # @return [String] merkle root
    def compute_root
      # Re-check here rather than trusting the constructor. +leaves+ is readable and its arrays
      # are mutable, so a structure that was rejected at construction can be assembled afterwards.
      validate_leaves!
      all_leaves = extract_leaves(@leaves)
      raise Error, 'leaves is empty' if all_leaves.empty?
      result = compute_node_hash(@leaves)
      result.unpack1('H*')
    end

    # Convert nested elements to nested hashes
    def self.convert_elements_to_hashes(node, config)
      if node.is_a?(Array)
        node.map { |child| convert_elements_to_hashes(child, config) }
      else
        # This is a leaf element, hash it and convert to hex
        config.tagged_hash(config.encode_element(node), config.leaf_tag).unpack1('H*')
      end
    end

    # Compute hash for a node in the structure (binary tree only)
    def compute_node_hash(node)
      if node.is_a?(Array)
        case node.length
        when 1
          # Single child - just return its hash
          compute_node_hash(node[0])
        when 2
          # Binary node: compute hash of left and right children
          left_hash = compute_node_hash(node[0])
          right_hash = compute_node_hash(node[1])
          
          # Combine hashes according to sort_hashes config
          combined = if config.sort_hashes
            [left_hash, right_hash].sort.join
          else
            left_hash + right_hash
          end
          
          config.tagged_hash(combined)
        else
          raise ArgumentError, "Binary tree nodes must have 1 or 2 children, got #{node.length}"
        end
      else
        # Leaf node: already a hash, convert to binary
        decode_hash(node)
      end
    end

    # Override generate_proof to work with nested structure
    def generate_proof(leaf_index)
      all_leaves = extract_leaves(@leaves)
      raise ArgumentError, 'leaf_index must be Integer' unless leaf_index.is_a?(Integer)
      raise ArgumentError, 'leaf_index out of range' if leaf_index < 0 || all_leaves.length <= leaf_index

      siblings, directions = siblings_with_directions(leaf_index)
      siblings = siblings.map { |sibling| bin_to_hex(sibling) }
      directions = [] if config.sort_hashes

      Proof.new(
        config: config,
        root: compute_root,
        leaf: all_leaves[leaf_index],
        siblings: siblings,
        directions: directions
      )
    end

    private

    # Extract all leaf hashes from the nested structure
    def extract_leaves(node)
      if node.is_a?(Array)
        node.flat_map { |child| extract_leaves(child) }
      else
        # This is a leaf hash
        [node]
      end
    end

    # Validate that the structure is a binary tree and that every leaf is a node hash.
    def validate_leaves!
      validate_binary_structure(@leaves, root: true)
      extract_leaves(@leaves).each { |leaf| decode_hash(leaf) }
    end

    # Validate that the structure is a binary tree (exactly 2 children per node)
    # @param [Object] node A subtree (nested Array) or a leaf hash.
    # @param [Boolean] root Whether +node+ is the whole tree.
    # @param [Integer] depth How far below the root +node+ sits.
    def validate_binary_structure(node, root: false, depth: 0)
      return unless node.is_a?(Array)
      # +depth+ counts the branches above this node, so a node here puts its children at
      # depth + 1. Stopping at MAX_DEPTH keeps the deepest leaf within MAX_DEPTH branches,
      # which is what Proof::MAX_SIBLINGS allows a proof to carry.
      raise ArgumentError, "Binary tree must not be deeper than #{MAX_DEPTH}" if depth >= MAX_DEPTH

      case node.length
      when 0
        raise ArgumentError, "Binary tree nodes cannot be empty"
      when 1
        # A node with one child contributes no branch hash, it just passes the child up.
        # That would let [[a]] and [a, [b]] commit to the same root as [a] and [a, b].
        # A tree holding a single leaf is the one case where there is nothing to confuse it with.
        unless root && !node[0].is_a?(Array)
          raise ArgumentError, "Binary tree nodes must have 2 children unless the tree is a single leaf"
        end
      when 2
        node.each { |child| validate_binary_structure(child, depth: depth + 1) }
      else
        raise ArgumentError, "Binary tree nodes can have at most 2 children, got #{node.length}"
      end
    end
    
    # Override siblings_with_directions for proof generation
    def siblings_with_directions(leaf_index)
      siblings = []
      directions = []
      collect_path(@leaves, leaf_index, siblings, directions)
      [siblings, directions]
    end

    # Walk down the structure toward the leaf at +index+ (counted within +node+), collecting the
    # sibling hash and its direction at each branch. Siblings are collected deepest first, the
    # order Proof#valid? folds them in.
    # The descent is driven by the index rather than by the leaf value, so duplicate leaf hashes
    # still yield the proof for the requested position.
    # @param [Object] node A subtree (nested Array) or a leaf hash.
    # @param [Integer] index The leaf index within +node+.
    # @param [Array] siblings Collected sibling hashes(binary format).
    # @param [Array] directions Collected directions(0: left, 1: right).
    def collect_path(node, index, siblings, directions)
      return unless node.is_a?(Array)

      if node.length == 1
        # Single child contributes no sibling, its hash is passed through unchanged.
        return collect_path(node[0], index, siblings, directions)
      end

      left, right = node
      left_leaves = leaf_count(left)
      if index < left_leaves
        collect_path(left, index, siblings, directions)
        siblings << compute_node_hash(right)
        directions << 1 # sibling is on the right
      else
        collect_path(right, index - left_leaves, siblings, directions)
        siblings << compute_node_hash(left)
        directions << 0 # sibling is on the left
      end
    end

    # Count the leaves under +node+.
    # @param [Object] node A subtree (nested Array) or a leaf hash.
    # @return [Integer] Number of leaves.
    def leaf_count(node)
      node.is_a?(Array) ? node.sum { |child| leaf_count(child) } : 1
    end

    # Not used in custom tree - structure is determined by nested array
    def build_next_level(nodes)
      raise NotImplementedError, "CustomTree uses structure-based computation"
    end
    
  end
end