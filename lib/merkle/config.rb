module Merkle
  # Merkle tree configuration class.
  class Config

    HASH_TYPES = [:sha256, :double_sha256]

    attr_reader :hash_type, :leaf_tag, :branch_tag, :sort_hashes

    def initialize(hash_type: :double_sha256, leaf_tag: '', branch_tag: '', sort_hashes: false)
      raise ArgumentError, "hash_type #{hash_type} does not supported." unless HASH_TYPES.include?(hash_type)
      raise ArgumentError, "leaf_tag must be string." unless leaf_tag.is_a?(String)
      raise ArgumentError, "internal_tag must be string." unless branch_tag.is_a?(String)
      raise ArgumentError, "sort_hashes must be boolean." unless sort_hashes.is_a?(TrueClass) || sort_hashes.is_a?(FalseClass)
      @hash_type = hash_type
      @leaf_tag = leaf_tag
      @branch_tag = branch_tag
      @sort_hashes = sort_hashes
    end

    # Bitcoin configuration.
    # @return [Merkle::Config]
    def self.bitcoin
      Config.new
    end

    # Taptree configuration.
    # @return [Merkle::Config]
    def self.taptree
      Config.new(leaf_tag: 'TapLeaf', branch_tag: 'TapBranch', sort_hashes: true)
    end
  end
end