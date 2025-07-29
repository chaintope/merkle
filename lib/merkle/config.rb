module Merkle
  # Merkle tree configuration class.
  class Config
    include Util

    # Supported Hash type.
    HASH_TYPES = [:sha256, :double_sha256]

    attr_reader :hash_type, :branch_tag, :sort_hashes

    # Constructor
    # @param [Symbol] hash_type The hashing algorithm used to hash the internal nodes.
    # @param [String] branch_tag Tags to use when hashing internal nodes.
    # @param [Boolean] sort_hashes Whether to sort internal nodes in lexicographical order and hash them.
    # If you enable this, Merkle::Proof's directions are not required.
    # @raise [ArgumentError]
    def initialize(hash_type: :sha256, branch_tag: '', sort_hashes: true)
      raise ArgumentError, "hash_type #{hash_type} does not supported." unless HASH_TYPES.include?(hash_type)
      raise ArgumentError, "internal_tag must be string." unless branch_tag.is_a?(String)
      raise ArgumentError, "sort_hashes must be boolean." unless sort_hashes.is_a?(TrueClass) || sort_hashes.is_a?(FalseClass)
      @hash_type = hash_type
      @branch_tag = branch_tag
      @sort_hashes = sort_hashes
    end

    # Bitcoin configuration.
    # @return [Merkle::Config]
    def self.bitcoin
      Config.new(hash_type: :double_sha256, sort_hashes: false)
    end

    # Taptree configuration.
    # @return [Merkle::Config]
    def self.taptree
      Config.new(branch_tag: 'TapBranch')
    end

    # Generate tagged hash.
    # @param [String] data The data to be hashed.
    # @param [String] tag Tag string used tagging.
    # @return [String] Tagged hash value.
    def tagged_hash(data, tag = branch_tag)
      raise ArgumentError, "data must be string." unless data.is_a?(String)
      data = [data].pack('H*') if hex_string?(data)

      unless tag.empty?
        tag_hash = Digest::SHA256.digest(tag)
        data = tag_hash + tag_hash + data
      end

      case hash_type
      when :sha256
        Digest::SHA256.digest(data)
      when :double_sha256
        Digest::SHA256.digest(Digest::SHA256.digest(data))
      end
    end
  end
end