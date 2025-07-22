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
    # @return [String] merkle root (hex value).
    def compute_root
      raise NotImplementedError
    end

    private

    def hash_internal_node(data)
      raise ArgumentError, "data must be string." unless data.is_a?(String)

      data = [data].pack('H*') if data.match?(/\A[0-9a-fA-F]+\z/)
      unless config.branch_tag.empty?
        tag_hash = Digest::SHA256.digest(branch_tag)
        data = tag_hash + tag_hash + data
      end

      case config.hash_type
      when :sha256
        Digest::SHA256.digest(data)
      when :double_sha256
        Digest::SHA256.digest(Digest::SHA256.digest(data))
      end
    end
  end
end