// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "../src/targets/Malicious.sol";

contract Unwise {

  uint256 public blah;
  address public test;

  function callUnwisely(address target, bytes calldata data) public {
    uint256 stipend = gasleft() - 5000;
    (bool success,) = target.delegatecall{gas: stipend}(data);
    require(success);
  }

}

contract MaliciousTest is Test {

    Unwise unwise;
    Malicious malicious;

    /// =================
    /// ===== SETUP =====
    /// =================
    function setUp() public {

      malicious = new Malicious();
      unwise = new Unwise();
    }

    function testMalicious() public {
      bytes memory data = abi.encodeCall(malicious.setIndex, (0, bytes32(uint256(42))));
      assertEq(unwise.blah(), 0);
      unwise.callUnwisely(address(malicious), data);
      assertEq(unwise.blah(), 42);


      data = abi.encodeCall(malicious.setIndex, (1, bytes32(uint256(0xcafebabe))));
      assertEq(unwise.test(), address(0));
      unwise.callUnwisely(address(malicious), data);
      assertEq(unwise.test(), address(uint160(0xcafebabe)));



    }

}