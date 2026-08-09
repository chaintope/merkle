module Merkle
  module Util

    # Size of a node hash in bytes. Leaves, siblings and internal nodes are all this size.
    HASH_SIZE = 32

    # Deepest tree accepted. A tree deeper than this cannot be walked without risking a
    # SystemStackError, which is not a StandardError and so escapes a caller's rescue.
    # 128 is also the deepest a BIP341 script tree can be.
    MAX_DEPTH = 128

    # Check whether +data+ is hex string or not.
    # An odd-length string is not a hex string. Treating it as one would let
    # +pack('H*')+ pad the missing nibble with zero, so 'abc' and 'abc0' would
    # collide.
    # @param [String] data
    # @return [Boolean]
    # @raise [ArgumentError]
    def hex_string?(data)
      raise ArgumentError, 'data must be string' unless data.is_a?(String)
      data.length.even? && data.match?(/\A[0-9a-fA-F]+\z/)
    end

    # Check whether +hex+ is the hex representation of a node hash.
    # @param [String] hex
    # @return [Boolean]
    def node_hash?(hex)
      return false unless hex.is_a?(String)
      # Match on the bytes. Matching the string itself raises on a value that claims to be UTF-8
      # but holds invalid bytes, which would surface as an unrelated ArgumentError.
      bytes = hex.b
      bytes.bytesize == HASH_SIZE * 2 && bytes.match?(/\A[0-9a-fA-F]+\z/)
    end

    # Convert a node hash from its hex representation to binary.
    # Node hashes are always +HASH_SIZE+ bytes written as hex, so anything else is rejected
    # rather than guessed at. Accepting arbitrary lengths here would make the concatenation
    # in an internal node ambiguous: ['aa', 'bbcc'] and ['aabb', 'cc'] would hash alike.
    # @param [String] hex
    # @return [String] Binary format hash.
    # @raise [ArgumentError]
    def decode_hash(hex)
      raise ArgumentError, 'hash must be string' unless hex.is_a?(String)
      raise ArgumentError, "hash must be a #{HASH_SIZE * 2}-character hex string" unless node_hash?(hex)
      [hex].pack('H*')
    end

    # Convert binary string +data+ to hex string.
    # @param [String] data
    # @return [String]
    # @raise [ArgumentError]
    def bin_to_hex(data)
      raise ArgumentError, 'data must be string' unless data.is_a?(String)
      data.unpack1('H*')
    end

    # Combine two elements(+left+ and +right+) with sort configuration.
    # @param [Merkle::Config] config
    # @param [String] left Left element(binary format).
    # @param [String] right Right element(binary format).
    # @return [String] Combined string.
    # @raise [ArgumentError]
    def combine_sorted(config, left, right)
      raise ArgumentError, "config must be Merkle::Config" unless config.is_a?(Merkle::Config)
      raise ArgumentError, "left must be string" unless left.is_a?(String)
      raise ArgumentError, "right must be string" unless right.is_a?(String)
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
