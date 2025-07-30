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
      # Validate nested structure before calling super
      validate_leaves!(extract_leaves(leaves))
    end

    # Create tree from elements with custom structure
    # @param [Merkle::Config] config Configuration for merkle tree.
    # @param [Array] elements A nested array of elements that will be hashed to become leaves.
    # @param [String] leaf_tag An optional tag to use when computing the leaf hash.
    def self.from_elements(config:, elements:, leaf_tag: '')
      raise ArgumentError, 'config must be Merkle::Config' unless config.is_a?(Merkle::Config)
      raise ArgumentError, 'elements must be Array' unless elements.is_a?(Array)
      raise ArgumentError, 'leaf_tag must be string' unless leaf_tag.is_a?(String)
      
      # Convert elements to hashes while preserving structure
      hashed_structure = convert_elements_to_hashes(elements, config, leaf_tag)
      
      self.new(config: config, leaves: hashed_structure)
    end

    # Compute merkle root using custom structure
    # @return [String] merkle root
    def compute_root
      all_leaves = extract_leaves(@leaves)
      raise Error, 'leaves is empty' if all_leaves.empty?
      result = compute_node_hash(@leaves)
      result.unpack1('H*')
    end

    # Convert nested elements to nested hashes
    def self.convert_elements_to_hashes(node, config, leaf_tag)
      if node.is_a?(Array)
        node.map { |child| convert_elements_to_hashes(child, config, leaf_tag) }
      else
        # This is a leaf element, hash it and convert to hex
        config.tagged_hash(node, leaf_tag).unpack1('H*')
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
        hex_to_bin(node)
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

    # Validate that all leaves are valid hex strings and structure is binary
    def validate_leaves!(leaves_to_validate)
      leaves_to_validate.each do |leaf|
        raise ArgumentError, "leaf hash must be string." unless leaf.is_a?(String)
      end
      validate_binary_structure(@leaves)
    end
    
    # Validate that the structure is a binary tree (max 2 children per node)
    def validate_binary_structure(node)
      if node.is_a?(Array)
        if node.length == 0
          raise ArgumentError, "Binary tree nodes cannot be empty"
        elsif node.length > 2
          raise ArgumentError, "Binary tree nodes can have at most 2 children, got #{node.length}"
        end
        node.each { |child| validate_binary_structure(child) }
      end
    end
    
    # Override siblings_with_directions for proof generation
    def siblings_with_directions(leaf_index)
      all_leaves = extract_leaves(@leaves)
      target_leaf = all_leaves[leaf_index]
      siblings = []
      directions = []
      
      # Build proof by finding the path to the target leaf
      proof_path = build_proof_path(@leaves, target_leaf)
      
      proof_path.each do |level_info|
        next if level_info[:siblings].empty?
        
        level_info[:siblings].each do |sibling|
          siblings << sibling[:hash]
          directions << sibling[:direction]
        end
      end
      
      [siblings, directions]
    end
    
    # Build the proof path with siblings at each level
    def build_proof_path(node, target_leaf, path = [])
      if node.is_a?(Array)
        # Find which child contains the target
        node.each_with_index do |child, idx|
          child_path = build_proof_path(child, target_leaf, path)
          
          if child_path
            # Found the path, now collect siblings at this level
            level_siblings = []
            node.each_with_index do |sibling, sibling_idx|
              next if sibling_idx == idx  # Skip the path we're on
              
              sibling_hash = compute_node_hash(sibling)
              direction = sibling_idx < idx ? 0 : 1
              level_siblings << { hash: sibling_hash, direction: direction }
            end
            
            return child_path + [{ siblings: level_siblings }]
          end
        end
        nil
      else
        # Leaf node
        if node == target_leaf
          []
        else
          nil
        end
      end
    end

    # Find the leaf index by searching through the tree
    def find_leaf_index(node, target_leaf, current_index = [0])
      if node.is_a?(Array)
        node.each do |child|
          result = find_leaf_index(child, target_leaf, current_index)
          return result if result
        end
        nil
      else
        # This is a leaf
        if node == target_leaf
          current_index[0]
        else
          current_index[0] += 1
          nil
        end
      end
    end

    # Not used in custom tree - structure is determined by nested array
    def build_next_level(nodes)
      raise NotImplementedError, "CustomTree uses structure-based computation"
    end
    
  end
end