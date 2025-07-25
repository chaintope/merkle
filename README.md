# Merkle

A Ruby library for Merkle tree construction and proof generation with support for multiple tree structures and hashing algorithms.

## Features

- **Multiple tree structures**: Binary Tree (Bitcoin-compatible) and Adaptive Tree implementations
- **Flexible configuration**: Support for different hash algorithms (SHA256, Double SHA256) and tagged hashing
- **Proof generation and verification**: Generate and verify Merkle proofs for any leaf
- **Sorted hashing support**: Optional lexicographical sorting for deterministic tree construction

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'merkle'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install merkle

## Usage

### Basic Example

```ruby
require 'merkle'

# Create configuration
config = Merkle::Config.new(hash_type: :sha256)

# Method 1: Using pre-hashed leaves
leaves = [
  'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3',
  'b3a8e0e1f9ab1bfe3a36f231f676f78bb30a519d2b21e6c530c0eee8ebb4a5d0',
  'c3c9bc9a6c7c5b4e8c3b6b5a2a8c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c'
]

# Create binary tree (Bitcoin-compatible)
tree = Merkle::BinaryTree.new(config: config, leaves: leaves)

# Compute merkle root
root = tree.compute_root
puts "Merkle root: #{root}"

# Generate proof for leaf at index 1
proof = tree.generate_proof(1)
puts "Proof siblings: #{proof.siblings}"
puts "Proof directions: #{proof.directions}"

# Verify proof
puts "Proof valid: #{proof.valid?}"
```

### Using from_elements

```ruby
# Method 2: Using from_elements to automatically hash raw data
elements = ['hello', 'world', 'merkle', 'tree']

# Create tree from raw elements
tree = Merkle::BinaryTree.from_elements(
  config: config, 
  elements: elements
)

# The elements are automatically hashed before building the tree
root = tree.compute_root
puts "Root from elements: #{root}"

# With optional leaf tag for tagged hashing (e.g., Taproot)
taproot_config = Merkle::Config.taptree
tagged_tree = Merkle::AdaptiveTree.from_elements(
  config: taproot_config,
  elements: elements,
  leaf_tag: 'TapLeaf'  # Optional tag for leaf hashing
)

# Generate and verify proof
proof = tree.generate_proof(0)
puts "Proof for first element valid: #{proof.valid?}"
```

### Adaptive Tree Example

```ruby
# Create adaptive tree for better performance with frequently accessed leaves
adaptive_tree = Merkle::AdaptiveTree.new(config: config, leaves: leaves)

root = adaptive_tree.compute_root
proof = adaptive_tree.generate_proof(0)
puts "Adaptive tree proof valid: #{proof.valid?}"
```

### Configuration Options

```ruby
# Bitcoin-compatible configuration with double SHA256
bitcoin_config = Merkle::Config.new(hash_type: :double_sha256)

# Configuration with tagged hashing (Taproot-style)
taproot_config = Merkle::Config.taptree

# Configuration with sorted hashing (no directions needed in proofs)
sorted_config = Merkle::Config.new(
  hash_type: :sha256,
  sort_hashes: true
)
```

## Architecture

### Tree Structures

- **BinaryTree**: Bitcoin-compatible merkle tree that duplicates odd nodes
- **AdaptiveTree**: Unbalanced tree that promotes odd nodes to higher levels for optimized access patterns

### Proof System

The library generates compact Merkle proofs that include:
- `siblings`: Array of sibling hashes needed for verification
- `directions`: Array indicating left (0) or right (1) position at each level
- `root`: The merkle root hash
- `leaf`: The original leaf value

### Verification

```ruby
proof = tree.generate_proof(leaf_index)
is_valid = proof.valid? # Returns true/false
```
