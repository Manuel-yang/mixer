pragma circom 2.0.0;

include "./getMerkleRoot.circom";
include "./circuits/mimc.circom";
include "./circuits/bitify.circom";



template Withdraw(k) {
    signal input root;
    signal input nullifierHash;

    signal input secret;
    signal input paths2_root[k];
    signal input paths2_root_pos[k];

    component leaf = MiMC7(91);
    leaf.x_in <== secret;
    leaf.k <== 0;

    component computed_root = GetMerkleRoot(k);
    computed_root.leaf <== leaf.out;

    for (var w = 0; w < k; w++) {
        computed_root.paths2_root[w] <== paths2_root[w];
        computed_root.paths2_root_pos[w] <== paths2_root_pos[w];
    }
    log(computed_root.out);
    root === computed_root.out;

    component cmt_index = Bits2Num(k);
    for ( var i = 0; i < k; i++) {
        cmt_index.in[i] <== paths2_root_pos[i];
    }

    component nullifier = MiMC7(91);
    nullifier.x_in <== cmt_index.out;
    nullifier.k <== secret;

    nullifierHash === nullifier.out;
}

component main{public [root, nullifierHash]} = Withdraw(8);