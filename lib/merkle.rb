# frozen_string_literal: true

require_relative "merkle/version"
require_relative 'merkle/util'
require_relative 'merkle/config'
require_relative 'merkle/abstract_tree'
require_relative 'merkle/binary_tree'
require_relative 'merkle/adaptive_tree'
require_relative 'merkle/custom_tree'
require_relative 'merkle/proof'

# Merkle tree module.
module Merkle

  class Error < StandardError; end
  # Your code goes here...
end
