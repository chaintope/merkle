# Merkle

A Ruby library for Merkle tree construction and proof generation with support for multiple tree structures and hashing algorithms.

## Features

- **Multiple tree structures**: Binary Tree (Bitcoin-compatible), Adaptive Tree, and Custom Tree implementations
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
# element_encoding says how the elements passed to .from_elements are read:
#   :hex    - elements are hex strings and are decoded before hashing
#   :binary - elements are byte strings and are hashed as-is
#   :auto   - legacy mode, see "Upgrading from 0.4.0 and earlier"
# It has no default: guessing it silently changes the merkle root.
config = Merkle::Config.new(element_encoding: :binary, hash_type: :sha256)

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
taproot_config = Merkle::Config.taptree(element_encoding: :binary)
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

### Custom Tree Example

```ruby
# CustomTree allows you to define your own tree structure using nested arrays
# This gives you precise control over how leaves are grouped

# Example 1: Basic usage with pre-hashed leaves
# Leaves are always 64-character hex strings, the same form #compute_root returns.
leaf_a = config.tagged_hash(config.encode_element('A')).unpack1('H*')
leaf_b = config.tagged_hash(config.encode_element('B')).unpack1('H*')
leaf_c = config.tagged_hash(config.encode_element('C')).unpack1('H*')
leaf_d = config.tagged_hash(config.encode_element('D')).unpack1('H*')

# Define structure: [[A, [B, C]], D]
nested_leaves = [[leaf_a, [leaf_b, leaf_c]], leaf_d]
custom_tree = Merkle::CustomTree.new(config: config, leaves: nested_leaves)

root = custom_tree.compute_root
puts "Custom tree root: #{root}"

# Valid structures:
# - [A, B] → Simple binary node
# - [[A, B], C] → Left subtree with right leaf
# - [A] → A tree holding a single leaf
# Invalid: [A, B, C] → Error (max 2 children per node)
# Invalid: [[A, B]] → Error (a single-child node just passes its child's hash up,
#                     so it would commit to the same root as [A, B])
```

### Configuration Options

```ruby
# Bitcoin-compatible configuration with double SHA256
bitcoin_config = Merkle::Config.new(element_encoding: :hex, hash_type: :double_sha256)

# Configuration with tagged hashing (Taproot-style)
taproot_config = Merkle::Config.taptree(element_encoding: :hex)

# Configuration with non-sorted hashing (directions needed in proofs)
non_sorted_config = Merkle::Config.new(
  element_encoding: :binary,
  hash_type: :sha256,
  sort_hashes: false
)
```

## Architecture

### Tree Structures

- **BinaryTree**: Bitcoin-compatible merkle tree that duplicates odd nodes
- **AdaptiveTree**: Unbalanced tree that promotes odd nodes to higher levels for optimized access patterns
- **CustomTree**: User-defined tree structure using nested arrays for precise control over leaf grouping

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

`#valid?` folds `leaf` upwards through `siblings` and compares the result to `root`. It answers
"do these hashes chain to this root", and nothing more. In particular it does not check that
`leaf` sits at the bottom of the tree.

**The verifier must derive `leaf` itself.** Hash the data you care about and build the proof
around that value:

```ruby
leaf = config.tagged_hash(config.encode_element(my_data), 'MyLeaf').unpack1('H*')
proof = Merkle::Proof.new(config: config, root: trusted_root, leaf: leaf,
                          siblings: received_siblings, directions: received_directions)
proof.valid?
```

Taking `leaf` from whoever supplied the proof defeats it: any internal node of the tree is a
value that chains to the root, so it would be accepted as if it were a leaf.

## Security considerations

This library lets you build trees that are not second-preimage resistant, because Bitcoin's
transaction merkle tree is one of them and cannot be changed. Two properties are left to the
protocol built on top of it:

- **Domain separation.** Give `leaf_tag` and `branch_tag` different values so that a leaf hash
  can never equal an internal node hash. With both left empty, an attacker can craft an element
  whose leaf hash equals an internal node and prove membership of something that was never in
  the tree. `Config.taptree` sets `branch_tag`, but the leaf tag is yours to pass to
  `.from_elements`.
- **Duplicate leaves (CVE-2012-2459).** `BinaryTree` duplicates the last node when a level holds
  an odd number of them, exactly as Bitcoin does, so `[a, b, c]` and `[a, b, c, c]` share a root.
  Use `AdaptiveTree` or `CustomTree` if you do not need Bitcoin compatibility.

Element encoding, by contrast, is not left to guesswork: `element_encoding` is required on
`Config`, so `'hello'` and `'68656c6c6f'` cannot silently resolve to the same leaf.

### Upgrading from 0.4.0 and earlier

`element_encoding` has no default, so every `Config` construction has to be updated. Pick the
value that matches what you were already passing to `.from_elements`:

| What you pass as elements | Use |
| --- | --- |
| Hex strings | `:hex` |
| Raw byte strings | `:binary` |
| A mix of both | `:auto` |

`:auto` reproduces the old behaviour exactly, including its collisions: `'hello'` and
`'68656c6c6f'` share a leaf under it, and so do `'AB'` and `'ab'`. Use it to keep verifying roots
you already committed to, not for a new protocol. It reproduces 0.4.0; 0.3.1 and earlier also
padded odd-length hex, so `'abc'` and `'abc0'` shared a leaf there and no mode reproduces that.

Leaves are now always 64-character hex strings. If you were passing binary digests
(`config.tagged_hash(...)`) as leaves, append `.unpack1('H*')`.
