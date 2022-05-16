//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { PoseidonT3 } from "./Poseidon.sol"; //an existing library to perform Poseidon hash on solidity
import "./verifier.sol"; //inherits with the MerkleTreeInclusionProof verifier contract
//import "hardhat/console.sol";

contract MerkleTree is Verifier {
    uint256[16-1] public hashes; // the Merkle tree in flattened array form
    uint256 public index = 0; // the current index of the first unfilled leaf 
    uint256 public root; // the current Merkle root

    constructor() {
        // [assignment] initialize a Merkle tree of 8 with blank leaves
        // [3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 2, 2, 1, 1, 0]  // 15 elements
        //  l  r -------------------.
        // initialize
        uint j; 
        for (j =0; j < 8; j++) {
            hashes[j] = 0;
        }
        uint k;        
        for (k = 0; k<3; k++) {  // k = 0, 1, 2 
            // offset: 8, 12, 14 = 16 - 2**(3-k)
            // offset_previous: 0, 8, 12 
            uint offset_previous = 16 - 2**(4-k);
            uint offset = 16 - 2**(3-k);
            for (j = 0; j < 2**(2-k); j++) { 
                uint256[2] memory hash_pair;
                //console.log("hash_pair[0] index:", offset_previous + (2*j));
                hash_pair[0] = hashes[offset_previous + (2*j)];
                hash_pair[1] = hashes[offset_previous + (2*j)+1];
                hashes[offset + j] = PoseidonT3.poseidon(hash_pair);
            }
        }
    }

    function insertLeaf(uint256 hashedLeaf) public returns (uint256) {
        // [assignment] insert a hashed leaf into the Merkle tree
        // index = 0, ..., 7

        hashes[index] = hashedLeaf;
        uint pos =index;
        uint k;                
        for (k = 0; k < 3; k++) {  
            uint offset_previous = 16 - 2**(4-k);
            uint offset = 16 - 2**(3-k);
            uint pos_new = pos / 2; 
            uint is_right = pos % 2;  // 0: left, 1: right

            uint256[2] memory hash_pair;
            if (is_right == 0){
                hash_pair[0] = hashes[offset_previous + pos];
                hash_pair[1] = hashes[offset_previous + pos +1];  
            }
            else {
                hash_pair[0] = hashes[offset_previous + pos - 1];
                hash_pair[1] = hashes[offset_previous + pos];
            }   
            // new hash       
            hashes[offset + pos_new] = PoseidonT3.poseidon(hash_pair);
            pos = pos_new;
        }   

        // update index
        index += 1;

        return hashes[14]; 
    }

    function verify(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[1] memory input
        ) public view returns (bool) {

        // [assignment] verify an inclusion proof and check that the proof root matches current root
        bool b1 = verifyProof(a, b, c, input);
        bool b2 = (input[0] == hashes[14]); // input is equal to current root
        return b1 && b2;
    }
}
