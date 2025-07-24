require 'digest'

module Merkle
  # Base class for Merkle tree implementations
  class AbstractTree
    include Util

    attr_reader :config, :leaves

    # Constructor
    # @param [Merkle::Config] config Configuration for merkle tree.
    # @param [Array] leaves An array of leaves.
    # @raise [ArgumentError]
    def initialize(config:, leaves: [])
      raise ArgumentError, 'config must be Merkle::Config' unless config.is_a?(Merkle::Config)
      raise ArgumentError, 'leaves must be Array' unless leaves.is_a?(Array)
      @config = config
      @leaves = leaves
    end

    # Compute merkle root.
    # @return [String] merkle root (hex value). For Bitcoin, the endianness of this value must be reversed.
    # @raise [Merkle::Error] If leaves is empty.
    def compute_root
      raise Error, 'leaves is empty' if leaves.empty?
      # nodes = leaves
      nodes = leaves.map {|leaf| hex_to_bin(leaf) }
      while nodes.length > 1
        nodes = build_next_level(nodes)
      end
      root = nodes.first
      root.unpack1('H*')
    end

    # Generates a merkle proof for the specified +leaf_index+.
    # @param [Integer] leaf_index The leaf index.
    # @return [Merkle::Proof] The merkle proof.
    # @raise [ArgumentError] If invalid +leaf_index+ specified.
    def generate_proof(leaf_index)
      raise ArgumentError, 'leaf_index must be Integer' unless leaf_index.is_a?(Integer)
      raise ArgumentError, 'leaf_index out of range' if leaf_index < 0 || leaves.length <= leaf_index

      siblings, directions = siblings_with_directions(leaf_index)
      siblings = siblings.map{|sibling| hex_string?(sibling) ? sibling : sibling.unpack1('H*')}
      directions = [] if config.sort_hashes
      Proof.new(config: config, root: compute_root, leaf: leaves[leaf_index], siblings: siblings, directions: directions)
    end

    private

    # Gets the siblings that corresponds to +leaf_index+ and its directions (if necessary).
    # @param [Integer] leaf_index The leaf index.
    # @return [Array] An array of siblings and directions.
    def siblings_with_directions(leaf_index)
      raise NotImplementedError
    end

    # Get branch hash.
    # @param [String] data The data to be hashed.
    # @return [String] Branch hash value.
    def branch_hash(data)
      config.tagged_hash(data)
    end

    # Build next level in tree.
    # @param [Array] nodes Current level nodes in tree.
    # @return [Array] An array of next level nodes in tree.
    def build_next_level(nodes)
      raise NotImplementedError
    end
  end
end