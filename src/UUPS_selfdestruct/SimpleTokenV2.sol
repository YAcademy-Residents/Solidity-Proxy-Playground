// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// Contract generate by OpenZeppelin Wizard
// https://docs.openzeppelin.com/contracts/4.x/wizard

import "./SimpleToken.sol";

contract SimpleTokenV2 is SimpleToken {
  function version() public pure returns (string memory) {
    return "v2";
  }
}
