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
      Config.new(hash_type: :sha256, leaf_tag: 'TapLeaf', branch_tag: 'TapBranch', sort_hashes: true)
    end

    def leaf_hash(data)
      tagged_hash(data, tag_type: :leaf)
    end

    def branch_hash(data)
      tagged_hash(data, tag_type: :branch)
    end

    def tagged_hash(data, tag_type: :branch)
      raise ArgumentError, "data must be string." unless data.is_a?(String)
      data = [data].pack('H*') if hex_string?(data)

      tag =  case tag_type
             when :branch
               branch_tag
             when :leaf
               leaf_tag
             else
               raise ArgumentError, "tag_type must be :branch or :leaf"
             end
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

    def hex_string?(data)
      data.match?(/\A[0-9a-fA-F]+\z/)
    end
  end
end