module Merkle
  # The AdaptiveTree class implements an unbalanced binary tree structure for Merkle tree construction,
  # optimized for scenarios where frequently used scripts should be placed at shallower depths.
  # Unlike the standard Bitcoin Merkle tree which maintains a complete binary tree by duplicating odd elements,
  # AdaptiveTree promotes odd nodes to higher levels, creating variable-depth paths.
  class AdaptiveTree < AbstractTree

    private

    def siblings_with_directions(leaf_index)
      siblings = []
      directions = []
      
      current_index = leaf_index
      nodes = leaves.map {|leaf| hex_to_bin(leaf) }
      
      while nodes.length > 1
        # For adaptive tree, odd nodes are promoted to next level
        if current_index.even? && current_index + 1 < nodes.length
          # Current node has a right sibling
          sibling_index = current_index + 1
          directions << 1  # sibling is on the right
          siblings << nodes[sibling_index]
          current_index = current_index / 2
        elsif current_index.odd?
          # Current node has a left sibling
          sibling_index = current_index - 1
          directions << 0  # sibling is on the left
          siblings << nodes[sibling_index]
          current_index = current_index / 2
        else
          # Current node is the last node (odd), no sibling at this level
          # It gets promoted to the next level
          # Find its new index in the next level
          current_index = nodes.length / 2
        end
        
        # Move to next level
        nodes = build_next_level(nodes)
      end

      [siblings, directions]
    end

    def build_next_level(nodes)
      next_level = []
      nodes.each_slice(2) do |left, right|
        if right
          combined = combine_sorted(config, left, right)
          parent_hash = branch_hash(combined)
          next_level << parent_hash
        else
          next_level << left
        end
      end

      next_level
    end
  end
end