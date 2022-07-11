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

    function testGriefMigration() public {
        initializeMigration(alice, bob, TOTAL_SUPPLY, HALF_SUPPLY, true);
        (nftReceiverSelectors, nftReceiverPlugins) = initializeNFTReceiver();
        // Migrate to a vault with no permissions (just to test out migration)
        address[] memory modules = new address[](1);
        modules[0] = address(mockModule);


        uint256 nextId = bob.migrationModule.nextId() + 1;

        bob.migrationModule.join{value: 1 wei}(vault, nextId, HALF_SUPPLY);
        bool started = bob.migrationModule.commit(vault, nextId);
        uint256 intStarted = started ? 1 : 0;
        assertEq(intStarted, 1);

        // // Bob makes the proposal
        vm.expectRevert(
            abi.encodeWithSelector(
                IBuyout.InvalidState.selector,
                State.INACTIVE,
                State.LIVE
            )
        );

        bob.migrationModule.propose(
            vault,
            modules,
            nftReceiverPlugins,
            nftReceiverSelectors,
            TOTAL_SUPPLY * 2,
            1 ether
        );
    }


}
