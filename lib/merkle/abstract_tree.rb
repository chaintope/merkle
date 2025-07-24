require 'digest'

module Merkle
  class AbstractTree

    attr_reader :config, :leaves

    def initialize(config:, leaves: [])
      raise ArgumentError, 'config must be Merkle::Config' unless config.is_a?(Merkle::Config)
      raise ArgumentError, 'leaves must be Array' unless leaves.is_a?(Array)
      @config = config
      @leaves = leaves
    end

    # Compute merkle root
    # @return [String] merkle root (hex value). For Bitcoin, the endianness of this value must be reversed.
    # @raise [Merkle::Error] If leaves is empty.
    def compute_root
      raise Error, 'leaves is empty' if leaves.empty?
      nodes = leaves
      while nodes.length > 1
        nodes = build_next_level(nodes)
      end
      root = nodes.first
      config.hex_string?(root) ? root : root.unpack1('H*')
    end

    private

    def branch_hash(data)
      config.branch_hash(data)
    end

    def build_next_level
      raise NotImplementedError
    end

    def hash_internal_node(data)
      config.tagged_hash(data)
    end

    # Combine left node ant right node.
    # If sort_hashes in config enabled, sorted lexicographically then combined.
    # @param [String] left node value.
    # @return [String] right node value.
    # @return [String] combined data.
    def combine(left, right)
      if config.sort_hashes
        lh = left.unpack1('H*')
        rh = right.unpack1('H*')
        lh < rh ? left + right : right + left
      else
        left + right
      end
    end
  end
end