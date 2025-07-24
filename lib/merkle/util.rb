module Merkle
  module Util

    def hex_string?(data)
      data.match?(/\A[0-9a-fA-F]+\z/)
    end

    def hex_to_bin(data)
      hex_string?(data) ? [data].pack('H*') : data
    end

    def combine_sorted(config, left, right)
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