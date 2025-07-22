module Merkle
  # Merkle trees take the same approach as Bitcoin to construct a complete binary tree.
  # If the number of hashes in the list at a given level is odd,
  # the last one is duplicated before computing the next level (which is unusual in Merkle trees).
  # So keep in mind that this following merkle tree algorithm has a serious flaw related to duplicate elements,
  # resulting in a vulnerability (CVE-2012-2459).
  class BinaryTree < AbstractTree

    # Compute merkle root
    # @return [String] merkle root (hex value). For Bitcoin, the endianness of this value must be reversed.
    def compute_root
      nodes = leaves
      while nodes.length > 1
        nodes = build_next_level(nodes)
      end
      root = nodes.first
      root.match?(/\A[0-9a-fA-F]+\z/) ? root : root.unpack1('H*')
    end

    private

    def build_next_level(nodes)
      next_level = []
      nodes = nodes + [nodes.last] if nodes.length.odd?
      nodes.each_slice(2) do |left, right|
        combined = left + right
        parent_hash = hash_internal_node(combined)
        next_level << parent_hash
      end

      next_level
    end

  end

end