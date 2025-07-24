module Merkle
  module Util

    # Check whether +data+ is hex string or not.
    # @return [Boolean]
    # @raise [ArgumentError]
    def hex_string?(data)
      raise ArgumentError, 'data must be string' unless data.is_a?(String)
      data.match?(/\A[0-9a-fA-F]+\z/)
    end

    # Convert hex string +data+ to binary.
    # @return [String]
    # @raise [ArgumentError]
    def hex_to_bin(data)
      raise ArgumentError, 'data must be string' unless data.is_a?(String)
      hex_string?(data) ? [data].pack('H*') : data
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