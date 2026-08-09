module Merkle
  # Merkle tree configuration class.
  class Config
    include Util

    # Supported Hash type.
    HASH_TYPES = [:sha256, :double_sha256]

    # How the elements passed to .from_elements are turned into bytes.
    # :hex    - each element is a hex string and is decoded before hashing.
    # :binary - each element is already a byte string and is hashed as-is.
    # :auto   - each element is decoded if it looks like hex, otherwise hashed as-is.
    #
    # :auto exists to reproduce roots computed by 0.4.0 and earlier, where this was the only
    # behaviour. Do not choose it for a new protocol: 'hello' and '68656c6c6f' resolve to the
    # same leaf under it, and so do 'AB' and 'ab'. Note it reproduces 0.4.0, not 0.3.1 and
    # earlier, which also padded odd-length hex ('abc' and 'abc0' shared a leaf there).
    ELEMENT_ENCODINGS = [:hex, :binary, :auto]

    attr_reader :hash_type, :leaf_tag, :branch_tag, :sort_hashes, :element_encoding

    # Constructor
    # @param [Symbol] element_encoding How elements are interpreted, :hex, :binary or :auto.
    # This has no default on purpose. Guessing it silently changes the merkle root.
    # See ELEMENT_ENCODINGS before reaching for :auto.
    # @param [Symbol] hash_type The hashing algorithm used to hash the internal nodes.
    # @param [String] leaf_tag Tag to use when hashing leaves.
    # Give this and +branch_tag+ different values so that a leaf hash can never equal an internal
    # node hash. With both left empty the tree is not second-preimage resistant.
    # @param [String] branch_tag Tags to use when hashing internal nodes.
    # @param [Boolean] sort_hashes Whether to sort internal nodes in lexicographical order and hash them.
    # If you enable this, Merkle::Proof's directions are not required.
    # @raise [ArgumentError]
    def initialize(element_encoding:, hash_type: :sha256, leaf_tag: '', branch_tag: '', sort_hashes: true)
      raise ArgumentError, "element_encoding #{element_encoding} does not supported." unless ELEMENT_ENCODINGS.include?(element_encoding)
      raise ArgumentError, "hash_type #{hash_type} does not supported." unless HASH_TYPES.include?(hash_type)
      raise ArgumentError, "leaf_tag must be string." unless leaf_tag.is_a?(String)
      raise ArgumentError, "internal_tag must be string." unless branch_tag.is_a?(String)
      raise ArgumentError, "sort_hashes must be boolean." unless sort_hashes.is_a?(TrueClass) || sort_hashes.is_a?(FalseClass)
      @element_encoding = element_encoding
      @hash_type = hash_type
      @leaf_tag = leaf_tag
      @branch_tag = branch_tag
      @sort_hashes = sort_hashes
    end

    # Bitcoin configuration.
    # @param [Symbol] element_encoding How elements are interpreted, :hex, :binary or :auto.
    # @return [Merkle::Config]
    def self.bitcoin(element_encoding:)
      Config.new(element_encoding: element_encoding, hash_type: :double_sha256, sort_hashes: false)
    end

    # Taptree configuration.
    # @param [Symbol] element_encoding How elements are interpreted, :hex, :binary or :auto.
    # @return [Merkle::Config]
    def self.taptree(element_encoding:)
      Config.new(element_encoding: element_encoding, leaf_tag: 'TapLeaf', branch_tag: 'TapBranch')
    end

    # Convert +element+ into the byte string to be hashed, following element_encoding.
    # @param [String] element An element as given to .from_elements.
    # @return [String] Byte string.
    # @raise [ArgumentError] If +element+ does not match element_encoding.
    def encode_element(element)
      raise ArgumentError, "element must be string." unless element.is_a?(String)
      case element_encoding
      when :hex
        raise ArgumentError, "element must be a hex string." unless hex_string?(element)
        [element].pack('H*')
      when :binary
        element.b
      when :auto
        hex_string?(element) ? [element].pack('H*') : element.b
      end
    end

    # Generate tagged hash. +data+ is always hashed as a byte string.
    # To hash an element written as hex, pass it through #encode_element first.
    # @param [String] data The data to be hashed.
    # @param [String] tag Tag string used tagging.
    # @return [String] Tagged hash value.
    def tagged_hash(data, tag = branch_tag)
      raise ArgumentError, "data must be string." unless data.is_a?(String)
      raise ArgumentError, "tag must be a String." unless tag.is_a?(String)

      data_bin = data.b

      unless tag.empty?
        tag_bin = Digest::SHA256.digest(tag).b
        data_bin = tag_bin + tag_bin + data_bin
      end

      case hash_type
      when :sha256
        Digest::SHA256.digest(data_bin)
      when :double_sha256
        Digest::SHA256.digest(Digest::SHA256.digest(data_bin))
      end
    end
  end
end
