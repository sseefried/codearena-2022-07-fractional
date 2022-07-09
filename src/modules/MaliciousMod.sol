// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IVault} from "../interfaces/IVault.sol";
import {IVaultRegistry, Permission} from "../interfaces/IVaultRegistry.sol";
import "../targets/Malicious.sol";

contract MaliciousMod {

    Malicious malicious;

    constructor(address _malicious) {
      malicious = Malicious(_malicious);
    }

    /// @dev Callback for receiving ether when the calldata is empty
    receive() external payable {}

    function setIndex(address vault,
                      uint256 i,
                      bytes32 val,
                      bytes32[] calldata setIndexProof) external {
      bytes memory data = abi.encodeCall(malicious.setIndex, (i, val));

      IVault(payable(vault)).execute(address(malicious), data, setIndexProof);
    }


    function getLeafNodes() external view returns (bytes32[] memory nodes) {
        Permission[] memory permissions = getPermissions();
        nodes = new bytes32[](permissions.length);
        for (uint256 i; i < permissions.length; ) {
            // Hashes permission into leaf node
            nodes[i] = keccak256(abi.encode(permissions[i]));
            // Can't overflow since loop is a fixed size
            unchecked {
                ++i;
            }
        }
    }

    function getPermissions()
        public
        view
        returns (Permission[] memory permissions)
    {
        permissions = new Permission[](1);

        permissions[0] = Permission(
            address(this),
            address(malicious),
            malicious.setIndex.selector
        );
    }

}