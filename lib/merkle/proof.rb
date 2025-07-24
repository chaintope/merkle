module Merkle
  class Proof

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
  end
end