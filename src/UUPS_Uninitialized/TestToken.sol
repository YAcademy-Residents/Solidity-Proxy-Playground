// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";

// code partially borrowed from https://forum.openzeppelin.com/t/uups-proxies-tutorial-solidity-javascript/7786

contract TestToken is Initializable, ERC20Upgradeable, UUPSUpgradeable, OwnableUpgradeable {
    function initialize() initializer public {
      __ERC20_init("TestToken", "TTN");
      __Ownable_init();
      __UUPSUpgradeable_init();

      _mint(msg.sender, 1000 * 10 ** decimals());
    }

    // @note this function should have the onlyOwner modifier
    function _authorizeUpgrade(address) internal override onlyOwner {

    }

    constructor() {} // @note the constructor incorrectly has an `initializer` modifier in the OZ example here: https://forum.openzeppelin.com/t/uups-proxies-tutorial-solidity-javascript/7786
}