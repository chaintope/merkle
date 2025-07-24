module Merkle
  class Proof
    include Util

    attr_reader :config, :root, :leaf, :siblings, :directions

    # Constructor.
    # @param [Merkle::Config] config
    # @param [String] root
    # @param [String] leaf
    # @param [Array] siblings
    # @param [Array] directions Array of positions at each level(0: left, 1: right),
    # only required if sort_hashes is false in config.
    def initialize(config:, root:, leaf:, siblings:, directions: [])
      raise ArgumentError, 'config must be a Merkle::Config' unless config.is_a?(Merkle::Config)
      raise ArgumentError, 'root must be string' unless root.is_a?(String)
      raise ArgumentError, 'leaf must be string' unless leaf.is_a?(String)
      raise ArgumentError, 'directions must be an Array' unless directions.is_a?(Array)
      raise ArgumentError, 'No directions are required because sorted_hash is enabled' if config.sort_hashes && !directions.empty?
      @config = config
      @root = root
      @leaf = leaf
      @siblings = siblings
      @directions = directions
    end

    # Verify the proof.
    # @return [Boolean] true if the proof is valid, false otherwise.
    def valid?
      current = hex_to_bin(leaf)

      siblings.each_with_index do |sibling, index|
        sibling_bin = hex_to_bin(sibling)
        
        if config.sort_hashes
          # Sort lexicographically when combining
          combined = combine_sorted(config, current, sibling_bin)
        else
          # Use direction to determine order
          direction = directions[index]
          combined = direction == 0 ? sibling_bin + current : current + sibling_bin
        end
        
        current = config.branch_hash(combined)
      end

      current.unpack1('H*') == root
    end

  end
end