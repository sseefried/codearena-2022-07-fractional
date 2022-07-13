// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

import "./TestUtil.sol";
import "../src/interfaces/IMigration.sol";

contract MigrationTest is TestUtil {
    /// =================
    /// ===== SETUP =====
    /// =================
    function setUp() public {
        setUpContract();
        alice = setUpUser(111, 1);
        bob = setUpUser(222, 2);

        vm.label(address(this), "MigrateTest");
        vm.label(alice.addr, "Alice");
        vm.label(bob.addr, "Bob");
    }

    function testGriefCommit() public {
        vm.warp(1657692668389);
        initializeMigration(alice, bob, TOTAL_SUPPLY, HALF_SUPPLY, true);
        (nftReceiverSelectors, nftReceiverPlugins) = initializeNFTReceiver();

        address[] memory modules = new address[](1);
        modules[0] = address(mockModule);
        // Bob makes the proposal
        bob.migrationModule.propose(
            vault,
            modules,
            nftReceiverPlugins,
            nftReceiverSelectors,
            TOTAL_SUPPLY * 2,
            1 ether
        );
        // Bob joins the proposal
        bob.migrationModule.join{value: 1 ether}(vault, 1, HALF_SUPPLY);

        // Alice submits a spurious proposal with a low target price
        // that she can easily provide
        alice.migrationModule.propose(
            vault,
            modules,
            nftReceiverPlugins,
            nftReceiverSelectors,
            TOTAL_SUPPLY * 2,
            1 wei
        );

        alice.migrationModule.join{value: 2 wei}(vault, 2, 0);
        bool aliceStarted = alice.migrationModule.commit(vault, 2);
        assertTrue(aliceStarted);

        // Bob cannot `commit` now since a buyout for a spurious
        // proposal has been made.
        vm.expectRevert(abi.encodeWithSelector(
                IBuyout.InvalidState.selector,
                State.INACTIVE,
                State.LIVE));
        bob.migrationModule.commit(vault, 1);

    }


}
