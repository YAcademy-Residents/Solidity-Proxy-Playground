// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

// code partially borrowed from https://forum.openzeppelin.com/t/uups-proxies-tutorial-solidity-javascript/7786

contract TestTokenV1 is Initializable, ERC20Upgradeable {
    function initialize() initializer public {
      __ERC20_init("TestToken", "TTN");

      _mint(msg.sender, 1000 * 10 ** decimals());
    }

    constructor() initializer {}
}