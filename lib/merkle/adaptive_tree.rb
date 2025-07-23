module Merkle
  # The AdaptiveTree class implements an unbalanced binary tree structure for Merkle tree construction,
  # optimized for scenarios where frequently used scripts should be placed at shallower depths.
  # Unlike the standard Bitcoin Merkle tree which maintains a complete binary tree by duplicating odd elements,
  # AdaptiveTree promotes odd nodes to higher levels, creating variable-depth paths.
  class AdaptiveTree < AbstractTree

    private

    def build_next_level(nodes)
      next_level = []
      nodes.each_slice(2) do |left, right|
        if right
          combined = combine(left, right)
          parent_hash = hash_internal_node(combined)
          next_level << parent_hash
        else
          next_level << left
        end
      end

      next_level
    end
  end
end