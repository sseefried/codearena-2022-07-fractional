// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract Malicious {

    bytes32 slot0;
    bytes32 slot1;
    bytes32 slot2;
    bytes32 slot3;
    bytes32 slot4;
    bytes32 slot5;
    bytes32 slot6;
    bytes32 slot7;
    bytes32 slot8;
    bytes32 slot9;

    function setIndex(uint256 i, bytes32 val) public {
      require (i < 10);
      if (i == 0) {
        slot0 = val;
      } else if (i == 1) {
        slot1 = val;
      } else if (i == 2) {
        slot2 = val;
      } else if (i == 3) {
        slot3 = val;
      } else if (i == 4) {
        slot4 = val;
      } else if (i == 5) {
        slot5 = val;
      } else if (i == 6) {
        slot6 = val;
      } else if (i == 7) {
        slot7 = val;
      } else if (i == 8) {
        slot8 = val;
      } else if (i == 9) {
        slot9 = val;
      }
    }

}