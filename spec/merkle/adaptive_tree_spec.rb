require 'spec_helper'

RSpec.describe Merkle::AdaptiveTree do
  let(:config) { Merkle::Config.taptree }
  let(:leaves) {[
    config.leaf_hash('c02220c6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee5ac'),
    config.leaf_hash('c02220f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f9ac'),
    config.leaf_hash('c0222031fe7061656bea2a36aa60a2f7ef940578049273746935d296426dc0afd86b68ac')
  ]}
  let(:tree) { described_class.new(config: config, leaves: leaves) }
  it do
    # tree leaves tree.
    #       N0
    #    /     \
    #   N1      C
    #  /  \
    # A    B
    expect(tree.compute_root).to eq('bf5790f5c07064bf0ffd25782122fe774d70f66b5feb914926d9be07bec340fd')

    # four leaves tree.
    #       N0
    #    /     \
    #   N1      N2
    #  /  \    /  \
    # A    B  C    D
    tree.leaves << config.leaf_hash('c02220a016430f275c30cb15f399aa807cc9bde6b2c4c80c84be3bb27912089c18e363ac')
    expect(tree.compute_root).to eq('4036d6059d4573a9928e48cfcde92c1db4252bb6bb4bc62dc0048feb51c6b4cd')
    # five leaves tree.
    #           N0
    #        /     \
    #       N1      E
    #    /     \
    #   N2      N3
    #  /  \    /  \
    # A    B  C    D
    tree.leaves << config.leaf_hash('c02220b256afd27b26b0db101fd4a3d99afdd876dd2aaa5be967198882476bf425c301ac')
    expect(tree.compute_root).to eq('600bec51f45ae5ef6a0bf05321891e643ea585cf2f65e46e3d16d205d43ac839')

    # six leaves tree.
    #            N0
    #        /        \
    #       N1         N2
    #    /     \      /  \
    #   N3      N4   E    F
    #  /  \    /  \
    # A    B  C    D
    tree.leaves << config.leaf_hash('c022200e5ba1cfed1fe76ff81558731b7279ed23ddd95ce0fd67adc94584e80abbe987ac')
    expect(tree.compute_root).to eq('981a53412c92098b732a4bbf84a3af811e028c0e3d0fec21fcc3934392684465')
  end

  context 'single node' do
    let(:leaves) {['36a39ed285a4ffdb141c16af1eb1029bf18a18a7fdc54c70561d9371714f0c74']}
    it do
      expect(tree.compute_root).to eq('36a39ed285a4ffdb141c16af1eb1029bf18a18a7fdc54c70561d9371714f0c74')
    end
  end
end