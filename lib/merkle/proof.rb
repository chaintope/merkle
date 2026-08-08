module Merkle
  class Proof
    include Util

    # Upper bound on the number of siblings, i.e. the depth of the tree the proof came from.
    # A proof longer than this cannot correspond to any realistic tree, so it is rejected
    # rather than hashed.
    MAX_SIBLINGS = 64

    attr_reader :config, :root, :leaf, :siblings, :directions

    # Constructor.
    # @param [Merkle::Config] config
    # @param [String] root
    # @param [String] leaf
    # @param [Array] siblings An array of sibling hashes(64-character hex strings).
    # @param [Array] directions Array of positions at each level(0: left, 1: right),
    # only required if sort_hashes is false in config.
    def initialize(config:, root:, leaf:, siblings:, directions: [])
      raise ArgumentError, 'config must be a Merkle::Config' unless config.is_a?(Merkle::Config)
      raise ArgumentError, 'root must be string' unless root.is_a?(String)
      raise ArgumentError, 'leaf must be string' unless leaf.is_a?(String)
      raise ArgumentError, 'siblings must be an Array' unless siblings.is_a?(Array)
      raise ArgumentError, "siblings must not exceed #{MAX_SIBLINGS} elements" if siblings.length > MAX_SIBLINGS
      siblings.each do |sibling|
        raise ArgumentError, 'sibling must be string' unless sibling.is_a?(String)
        raise ArgumentError, 'sibling must be a 64-character hex string' unless sibling.match?(/\A[0-9a-fA-F]{64}\z/)
      end
      raise ArgumentError, 'directions must be an Array' unless directions.is_a?(Array)
      raise ArgumentError, 'No directions are required because sorted_hash is enabled' if config.sort_hashes && !directions.empty?
      unless config.sort_hashes
        raise ArgumentError, 'directions must have the same length as siblings' unless directions.length == siblings.length
        raise ArgumentError, 'direction must be 0 or 1' unless directions.all? { |direction| direction == 0 || direction == 1 }
      end
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
        
        current = config.tagged_hash(combined)
      end

      current.unpack1('H*') == root
    end

  end
end