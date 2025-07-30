require 'spec_helper'

RSpec.describe Merkle::BinaryTree do

  describe 'bitcoin compatible' do
    let(:config) { Merkle::Config.bitcoin }
    let(:tree) { described_class.new(config: config, leaves: leaves) }
    let(:leaves) {[ # tx hash
      "5413f97b08de361a6bb32dbbd20e755499d39ad9870537d340a5393eaba4eb9d",
      "fc8bc019d625305199d825188539571556485f86c85def5d274c8ca9075860f3",
      "c161a6a8908cadca27adc921379c0bd5b7850087e918dda5b0b99f6652b97ee2",
      "d921cae6d9b9d7ef0ce4256961a9d2282980133d891138713a20ab07e7b29622",
      "08a913c98963c7107552ead9203c3d1dbe1cce79a47f429069be2267fd486ff4",
      "21fc1ac87120a5c2d9abe82ecb97288b73c6ac5d8ebcc251b94a1f8ba52a9c27",
      "b8bd1d8a4a86aaa8ee19085c24d0439d0cb42fbc0ebf01f7f226e54faf8b34ff",
      "d56008fffa70a5baae731ed3e4b76914204488e81d313989084fabecdcca5e35",
      "d7b2f334b972706bfe1da5ae5d989ee31f345f39e5841e2d3ee3602673613386",
      "c9f4f0461c03b0d218c2f6747d4ddba0d0909a6ff9e2679888f4bf27a3b65092",
      "5254289bd2797ab77593800b63cf70b45c36a3e04716b003f06c25f58abf1e7d",
      "f2701891b64e4bb35e5de9981eb3325d987e6f98678ab3016142fac314b54b37",
      "a345950c41f05b974cedd22474394d382f3492c9037866e94e8f85fa4d6f00bb",
      "7f117077147817cfd879d4a07a8845a52e8236737c97c625d8701720e5eaeda6",
      "263f69c3a8d11077cb1aa0519e271ef6cf085a4b3a863009b5005e010d9e6963",
      "12cd6babfa4f5ab83adfcc2d5c96e9e29fc59bf6320d209ebb12f0d641da25d0",
      "1273a51196a7f72271626a63cbb9f36814c995ee6439394dc3d600cf334c2978",
      "23b5818d9b8d686736cf65604479e72aa13f6dd3dd632d81682921836142b0f0",
      "4c841a38f8c12acbd13ab9d54073a56a0d027f7e28a6cb1bf5e038385ec367d8",
      "e4967fcd72010ad69c3763d8e5da5c832820e5ae2b47ba68c55cf44ceaf4ebbc"
    ]}
    it do
      expect(tree.compute_root).to eq('d3d4a973d5bfc4c13fb99f1f8c555a8a938bce79852a887b47693d3a71faade6')
      proof = tree.generate_proof(2)
      expect(proof.leaf).to eq('c161a6a8908cadca27adc921379c0bd5b7850087e918dda5b0b99f6652b97ee2')
      expect(proof.root).to eq('d3d4a973d5bfc4c13fb99f1f8c555a8a938bce79852a887b47693d3a71faade6')
      expect(proof.siblings.length).to eq(5)
      s1 = 'd921cae6d9b9d7ef0ce4256961a9d2282980133d891138713a20ab07e7b29622'
      s2 = '360dd5f78fa05649cb2e48eda2b7ddae5bd027ec8e2e2ec93e9dd9fd20a8fcae'
      s3 = 'a3b53b65fcef8f39e98e2908c2e19fee22227f2e279c8c9347e03f4dc14c91a5'
      s4 = 'f25c1d05fa8d7924228097a7b3060bf5b7acd884bc917b70ea0eeaafd0a8f7ba'
      s5 = 'a020236fd65606dcf110f40bae1884e525619e517d511d4abb84e8d708f12d56'
      expect(proof.siblings).to eq([s1, s2, s3, s4, s5])
      expect(proof.directions).to eq([1, 0, 1, 1, 1])
      expect(proof.valid?).to be true
    end

    context 'sorted_hash is true' do
      let(:config) { Merkle::Config.new(hash_type: :double_sha256, sort_hashes: true) }
      let(:leaves) {[
        "fc8bc019d625305199d825188539571556485f86c85def5d274c8ca9075860f3",
        "5413f97b08de361a6bb32dbbd20e755499d39ad9870537d340a5393eaba4eb9d",
        "c161a6a8908cadca27adc921379c0bd5b7850087e918dda5b0b99f6652b97ee2",
        "d921cae6d9b9d7ef0ce4256961a9d2282980133d891138713a20ab07e7b29622"
      ]}
      it do
        expect(tree.compute_root).to eq('18b7a9383070575b383c48915a9cac56965fa077c3630edbfa3d3631abc7c8e8')
        proof = tree.generate_proof(1)
        expect(proof.root).to eq('18b7a9383070575b383c48915a9cac56965fa077c3630edbfa3d3631abc7c8e8')
        expect(proof.siblings).to eq([tree.leaves[0], '30b9ce14745562e8734c93a4f9b81febd14f3c25d297a01fb69484eeff3f941b'])
        expect(proof.directions).to be_empty
        expect(proof.valid?).to be true
      end
    end

    context 'single node' do
      let(:leaves) {['36a39ed285a4ffdb141c16af1eb1029bf18a18a7fdc54c70561d9371714f0c74']}
      it do
        expect(tree.compute_root).to eq('36a39ed285a4ffdb141c16af1eb1029bf18a18a7fdc54c70561d9371714f0c74')
        proof = tree.generate_proof(0)
        expect(proof.siblings).to be_empty
        expect(proof.directions).to be_empty
        expect(proof.valid?).to be true
        expect{tree.generate_proof(1)}.to raise_error(ArgumentError, 'leaf_index out of range')
      end
    end

    context 'empty' do
      let(:leaves) {[]}
      it do
        expect{tree.compute_root}.to raise_error(Merkle::Error, 'leaves is empty')
      end
    end

  end
end

