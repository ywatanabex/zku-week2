pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/switcher.circom";

template CheckRootOneLevel(n) {
    assert(n >= 0);
    signal input in[2**(n+1)];
    signal output out[2**n];
    component poseidon[2**n];

    for (var i = 0; i < 2**n; i++) {
        poseidon[i] = Poseidon(2);
        poseidon[i].inputs[0] <== in[2 * i];
        poseidon[i].inputs[1] <== in[(2 * i) + 1];
        out[i] <== poseidon[i].out;
    }
} 


template CheckRoot(n) { // compute the root of a MerkleTree of n Levels 
    assert(n >= 1);
    signal input leaves[2**n];
    signal output root;
  
    // create components
    component one_level[n];
    for (var i = 0; i < n; i++) {
        one_level[i] = CheckRootOneLevel(i);        
    }

    // hash on leaves
    for (var j = 0; j < 2**n; j++) {
        one_level[n-1].in[j] <== leaves[j];
    }
    // hash on internal nodes
    for (var i = n-1; i > 0; i--) {
        for (var j = 0; j <2**i ; j++) {
            one_level[i-1].in[j] <== one_level[i].out[j];
        }
    }
    root <== one_level[0].out[0];
}

template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root; // note that this is an OUTPUT signal

    //[assignment] insert your code here to compute the root from a leaf and elements along the path
    component poseidon[n];
    component switcher[n];
    signal h[n+1];
    h[0] <== leaf;
    for (var i = 0; i < n; i++) {
         poseidon[i] = Poseidon(2);
         switcher[i] = Switcher();  // do nothing if sel=0     
         switcher[i].sel <== path_index[i];
         switcher[i].L <== h[i];
         switcher[i].R <== path_elements[i];
         poseidon[i].inputs[0] <== switcher[i].outL;
         poseidon[i].inputs[1] <== switcher[i].outR;
         h[i+1] <== poseidon[i].out;
    }
    root <== h[n];
}