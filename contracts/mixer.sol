// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.19;

import "./merkleTree.sol";
import {Groth16Verifier} from "./verifier.sol";

contract Mixer is MerkleTree, Groth16Verifier {
    mapping(uint256 => bool) public root;
    mapping(uint256 => bool) public nullifierHashes;
    mapping(uint256 => bool) public commitments;

    uint256 constant public AMOUNT = 0.01 ether;
    Groth16Verifier verifier;


    event Deposit(uint256 indexed commitment, uint256 leafIndex, uint256 timestamp);
    event Withdraw(address to, uint256 nullifierHash);
    event Forward(uint256 indexed commitment, uint256 leafIndex, uint256 timestamp);

    constructor (address _mimc, address _verifier) MerkleTree(_mimc) public {
        verifier = Groth16Verifier(_verifier);
    }


    function deposit(uint256 _commitment) payable public {
        require(!commitments[_commitment], "The commitment has been submitted");
        require(msg.value == AMOUNT);
        uint256 insertedIndex = insert(_commitment);
        commitments[_commitment] = true;
        roots[getRoot()] = true;
        emit Deposit(_commitment, insertedIndex, block.timestamp);
    }

    function withdraw(
        uint[2] calldata a,
        uint[2][2] calldata b,
        uint[2] calldata c,
        uint[2] calldata input) public {
            uint256 _nullifierHash = uint256(input[1]);
            uint256 _root = uint256(input[0]);

            require(!nullifierHashes[_nullifierHash], "The note hash been already spent");
            require(isKnownRoot(_root), "Cannot find your merkle root");
            require(verifier.verifyProof(a, b, c, input), "Invalid withdraw proof");

            nullifierHashes[_nullifierHash] = true;
            payable (msg.sender).transfer(AMOUNT);
            emit Withdraw(msg.sender, _nullifierHash);
        }
    
    function forward(
        uint[2] calldata a,
        uint[2][2] calldata b,
        uint[2] calldata c,
        uint[2] calldata input,
        uint256 _commitment
    ) public returns (address) {
        uint256 _nullifierHash = uint256(input[1]);
        uint256 _root = uint256(input[0]);

        require(!commitments[_commitment], "The commitment has been submitted");
        require(!nullifierHashes[_nullifierHash], "The note has been already spent");
        require(isKnownRoot(_root), "Cannot find your merkle root");
        require(verifier.verifyProof(a, b, c, input), "Invalid withdraw proof");

        uint insertedIndex = insert(_commitment);
        roots[getRoot()] = true;

        nullifierHashes[_nullifierHash] = true;
        emit Forward(_commitment, insertedIndex, block.timestamp);
    }

    function isKnownRoot(uint256 _root) public view returns(bool) {
        return roots[_root];
    }

}