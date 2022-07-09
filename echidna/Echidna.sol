// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./MerkleBase.sol";

contract Echidna {

  MerkleBase merkle;
  constructor() {
    merkle = new MerkleBase();
  }

  // function testLeaves(bytes32[] memory leaves, uint256 seed) public {
  //   require(leaves.length > 10);
  //   uint256 node = seed % leaves.length;
  //   for (uint256 i = 0; i < leaves.length; i++) {
  //     require(uint256(leaves[i]) > 0);
  //   }
  //   bytes32[] memory proof = merkle.getProof(leaves, node);
  //   bytes32 root = merkle.getRoot(leaves);
  //   assert(merkle.verifyProof(root, proof, leaves[node]));
  // }

  bytes32 lastHash = bytes32(0);


  function toBytes(uint256 x) internal returns (bytes memory b) {
    b = new bytes(32);
    assembly { mstore(add(b, 32), x) }
}
  function nextValue() internal returns (bytes32) {
    lastHash = keccak256(toBytes(uint256(lastHash) + 1));
    return lastHash;
  }


  function testLeaves(uint256 seed) public {
    uint256 len = seed % 200;
    bytes32[] memory leaves = new bytes32[](len);
    for (uint i = 0; i < len; i++) {
      leaves[i] = nextValue();
    }
    uint256 node = seed % len;

    bytes32[] memory proof = merkle.getProof(leaves, node);
    bytes32 root = merkle.getRoot(leaves);
    assert(merkle.verifyProof(root, proof, leaves[node]));
  }


}
