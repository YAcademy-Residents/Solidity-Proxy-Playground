// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

// Fun Fact: An ExplodingKitten can be exploded by another ExplodingKitten
contract ExplodingKitten is UUPSUpgradeable {

  bytes32 private constant _ROLLBACK_SLOT =
    0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

  function explode() public {
    StorageSlotUpgradeable.BooleanSlot
      storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(
        _ROLLBACK_SLOT
      );
    rollbackTesting.value = true;
    selfdestruct(payable(msg.sender));
  }

  function return42() public pure returns (uint256) {
    return 42;
  }

  // Any can call upgrade
  function _authorizeUpgrade(address newImplementation) internal override {}
}
