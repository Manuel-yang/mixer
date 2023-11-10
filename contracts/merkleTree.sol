pragma solidity 0.8.19;

abstract contract IMimc {
    function MiMCpe7(uint256 in_x, uint256 in_k) public virtual returns(uint256 out_x);
}


contract MerkleTree {
    mapping (uint256 => bool) public roots;
    uint public tree_depth = 8;
    uint public no_leaves = 256;

    struct Mtree {
        uint256 cur;
        uint256[256][9] leaves2;
    }

    Mtree public MT;
    IMimc mimc;

    event LeafAdded(uint256 index);
    event TestMimc(uint256);
    event merkleProof(uint256[8], uint256[8]);

    constructor(address _mimc) public {
        mimc = IMimc(_mimc);
    }

    function insert(uint256 com) public returns (uint256) {
        require(MT.cur != no_leaves);
        MT.leaves2[0][MT.cur] = com;
        updateTree();
        emit LeafAdded(MT.cur);
        MT.cur++;

        return MT.cur - 1;
    }

    function getMerkleProof(uint256 index) public returns (uint256[8] memory, uint256[8] memory) {
        uint256[8] memory address_bits;
        uint256[8] memory merkle_proof;

        for (uint256 i=0; i < tree_depth; i++) {
            if (index%2 == 0) {
                address_bits[i] = 1;
                merkle_proof[i] = getUniqueLeaf(MT.leaves2[i][index + 1], 1);
            }
            else {
                address_bits[i] = 0;
                merkle_proof[i] = getUniqueLeaf(MT.leaves2[i][index - 1],i);
            }
            index = uint256(index/2);
        }
        emit merkleProof(merkle_proof, address_bits);
        return(merkle_proof, address_bits);
    }

    function getMimc(uint256 input, uint256 sk) public returns(uint256) {
        emit TestMimc(mimc.MiMCpe7(input, sk));
        return mimc.MiMCpe7(input, sk);
    }

    function getUniqueLeaf(uint256 leaf, uint256 depth) public returns (uint256) {
        if (leaf == 0) {
            for (uint256 i = 0; i < depth; i++) {
                leaf = mimc.MiMCpe7(leaf, leaf);
            }
        } 
        return leaf;
    }

    function updateTree() public returns(uint256 root) {
        uint256 CurrentIndex = MT.cur;
        uint256 leaf1;
        uint256 leaf2;
        for ( uint256 i = 0; i < tree_depth; i++) {
            uint256 NextIndex = CurrentIndex;
            if ( CurrentIndex%2 == 0) {
                leaf1 = MT.leaves2[i][CurrentIndex];
                leaf2 = getUniqueLeaf(MT.leaves2[i][CurrentIndex + 1], i);
            }
            else {
                leaf1 = getUniqueLeaf(MT.leaves2[i][CurrentIndex - 1], i);
                leaf2 = MT.leaves2[i][CurrentIndex];
            }
            MT.leaves2[i+1][NextIndex] = mimc.MiMCpe7(leaf1, leaf2);
            CurrentIndex = NextIndex;
        }
        return MT.leaves2[tree_depth][0];
    }

    function getLeaf(uint256 j, uint256 k) public view returns(uint256 root) {
        root = MT.leaves2[j][k];
    }

    function getRoot() public view returns(uint256 root) {
        root = MT.leaves2[tree_depth][0];
    }
}