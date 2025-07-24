module Merkle
  # Merkle trees take the same approach as Bitcoin to construct a complete binary tree.
  # If the number of hashes in the list at a given level is odd,
  # the last one is duplicated before computing the next level (which is unusual in Merkle trees).
  # So keep in mind that this following merkle tree algorithm has a serious flaw related to duplicate elements,
  # resulting in a vulnerability (CVE-2012-2459).
  class BinaryTree < AbstractTree

    private

    def siblings_with_directions(leaf_index)
      siblings = []
      directions = []
      
      current_index = leaf_index
      nodes = leaves.map {|leaf| hex_to_bin(leaf) }
      
      while nodes.length > 1
        # If odd number of nodes, duplicate the last one
        nodes << nodes.last if nodes.length.odd?
        
        # Determine sibling index and direction (0=left, 1=right)
        if current_index.even?
          sibling_index = current_index + 1
          directions << 1  # sibling is on the right
        else
          sibling_index = current_index - 1
          directions << 0  # sibling is on the left
        end
        
        # Add sibling to the list
        siblings << nodes[sibling_index]
        
        # Move to next level
        current_index = current_index / 2
        nodes = build_next_level(nodes)
      end
      
      [siblings, directions]
    end

    def build_next_level(nodes)
      next_level = []
      nodes = nodes + [nodes.last] if nodes.length.odd?
      nodes.each_slice(2) do |left, right|
        combined = combine_sorted(config, left, right)
        parent_hash = branch_hash(combined)
        next_level << parent_hash
      end

      next_level
    end

  end

end