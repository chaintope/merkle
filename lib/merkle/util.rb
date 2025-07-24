module Merkle
  module Util

    def hex_string?(data)
      data.match?(/\A[0-9a-fA-F]+\z/)
    end

    def hex_to_bin(data)
      hex_string?(data) ? [data].pack('H*') : data
    end

  end
end